package store

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"

	"cortex/backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongoStore struct {
	client *mongo.Client
	db     *mongo.Database
}

func NewMongoStore(ctx context.Context, uri, dbName string) (*MongoStore, error) {
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		return nil, err
	}
	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}
	s := &MongoStore{client: client, db: client.Database(dbName)}
	if err := s.ensureSeeds(ctx); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *MongoStore) Close(ctx context.Context) error {
	return s.client.Disconnect(ctx)
}

func (s *MongoStore) col(name string) *mongo.Collection {
	return s.db.Collection(name)
}

func (s *MongoStore) ensureSeeds(ctx context.Context) error {
	modesCol := s.col("modes")
	count, err := modesCol.CountDocuments(ctx, bson.M{})
	if err != nil {
		return err
	}
	if count == 0 {
		preset := []any{
			models.Mode{ID: "mode-default", Name: "default", IsActive: true, IsPreset: true, CortexLevel: "off"},
			models.Mode{ID: "mode-study", Name: "study", IsActive: false, IsPreset: true, CortexLevel: "auto"},
			models.Mode{ID: "mode-office", Name: "office", IsActive: false, IsPreset: true, CortexLevel: "draft"},
			models.Mode{ID: "mode-home", Name: "home", IsActive: false, IsPreset: true, CortexLevel: "draft"},
			models.Mode{ID: "mode-gaming", Name: "gaming", IsActive: false, IsPreset: true, CortexLevel: "auto"},
		}
		if _, err := modesCol.InsertMany(ctx, preset); err != nil {
			return err
		}
	}

	cfgCol := s.col("cortex_config")
	cfgCount, err := cfgCol.CountDocuments(ctx, bson.M{})
	if err != nil {
		return err
	}
	if cfgCount == 0 {
		_, err = cfgCol.InsertOne(ctx, models.CortexConfig{Enabled: false, AutoReply: false, Scope: "global"})
		if err != nil {
			return err
		}
	}

	profileCol := s.col("profile")
	profileCount, err := profileCol.CountDocuments(ctx, bson.M{})
	if err != nil {
		return err
	}
	if profileCount == 0 {
		_, err = profileCol.InsertOne(ctx, models.UserProfile{ThemeMode: "system", LinkedAccounts: []string{}})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *MongoStore) SaveNotification(ctx context.Context, n *models.Notification) error {
	_, err := s.col("notifications").InsertOne(ctx, n)
	return err
}

func (s *MongoStore) ListNotifications(ctx context.Context) ([]models.Notification, error) {
	cur, err := s.col("notifications").Find(ctx, bson.M{"deleted": bson.M{"$ne": true}})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var out []models.Notification
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	sort.SliceStable(out, func(i, j int) bool {
		pi := models.PriorityRank[out[i].Priority]
		pj := models.PriorityRank[out[j].Priority]
		if pi == pj {
			return out[i].Timestamp.After(out[j].Timestamp)
		}
		return pi > pj
	})
	return out, nil
}

func (s *MongoStore) GetNotification(ctx context.Context, id string) (*models.Notification, error) {
	var n models.Notification
	err := s.col("notifications").FindOne(ctx, bson.M{"_id": id, "deleted": bson.M{"$ne": true}}).Decode(&n)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &n, nil
}

func (s *MongoStore) MarkRead(ctx context.Context, id string) error {
	res, err := s.col("notifications").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"is_read": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) MarkActioned(ctx context.Context, id string) error {
	res, err := s.col("notifications").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"is_actioned": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) SoftDeleteNotification(ctx context.Context, id string) error {
	res, err := s.col("notifications").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"deleted": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) ListModes(ctx context.Context) ([]models.Mode, error) {
	cur, err := s.col("modes").Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var modes []models.Mode
	if err := cur.All(ctx, &modes); err != nil {
		return nil, err
	}
	sort.SliceStable(modes, func(i, j int) bool { return modes[i].Name < modes[j].Name })
	return modes, nil
}

func (s *MongoStore) GetActiveMode(ctx context.Context) (*models.Mode, error) {
	var mode models.Mode
	err := s.col("modes").FindOne(ctx, bson.M{"is_active": true}).Decode(&mode)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &mode, nil
}

func (s *MongoStore) GetModeByID(ctx context.Context, id string) (*models.Mode, error) {
	var mode models.Mode
	err := s.col("modes").FindOne(ctx, bson.M{"_id": id}).Decode(&mode)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &mode, nil
}

func (s *MongoStore) CreateMode(ctx context.Context, mode *models.Mode) error {
	_, err := s.col("modes").InsertOne(ctx, mode)
	return err
}

func (s *MongoStore) UpdateMode(ctx context.Context, id string, mode *models.Mode) error {
	set := bson.M{
		"keywords":       mode.Keywords,
		"contact_ids":    mode.ContactIDs,
		"app_caps":       mode.AppCaps,
		"cortex_level":   mode.CortexLevel,
		"schedule_start": mode.ScheduleStart,
		"schedule_end":   mode.ScheduleEnd,
		"schedule_days":  mode.ScheduleDays,
	}
	if !mode.IsPreset && strings.TrimSpace(mode.Name) != "" {
		set["name"] = mode.Name
	}
	res, err := s.col("modes").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": set})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) ActivateMode(ctx context.Context, id string) error {
	_, err := s.col("modes").UpdateMany(ctx, bson.M{}, bson.M{"$set": bson.M{"is_active": false}})
	if err != nil {
		return err
	}
	res, err := s.col("modes").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"is_active": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) DeleteMode(ctx context.Context, id string) error {
	mode, err := s.GetModeByID(ctx, id)
	if err != nil {
		return err
	}
	if mode == nil {
		return mongo.ErrNoDocuments
	}
	if mode.IsPreset {
		return errors.New("preset mode cannot be deleted")
	}
	_, err = s.col("modes").DeleteOne(ctx, bson.M{"_id": id})
	return err
}

func (s *MongoStore) ListRules(ctx context.Context) ([]models.Rule, error) {
	opts := options.Find().SetSort(bson.D{{Key: "order", Value: 1}})
	cur, err := s.col("rules").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var rules []models.Rule
	if err := cur.All(ctx, &rules); err != nil {
		return nil, err
	}
	return rules, nil
}

func (s *MongoStore) NextRuleOrder(ctx context.Context) (int, error) {
	rules, err := s.ListRules(ctx)
	if err != nil {
		return 0, err
	}
	if len(rules) == 0 {
		return 1, nil
	}
	return rules[len(rules)-1].Order + 1, nil
}

func (s *MongoStore) CreateRule(ctx context.Context, rule *models.Rule) error {
	_, err := s.col("rules").InsertOne(ctx, rule)
	return err
}

func (s *MongoStore) UpdateRule(ctx context.Context, id string, rule *models.Rule) error {
	res, err := s.col("rules").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": rule})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) DeleteRule(ctx context.Context, id string) error {
	res, err := s.col("rules").DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return s.compactRuleOrder(ctx)
}

func (s *MongoStore) ReorderRules(ctx context.Context, pairs []map[string]any) error {
	for _, pair := range pairs {
		id, _ := pair["id"].(string)
		ord, _ := pair["order"].(float64)
		if id == "" {
			continue
		}
		_, err := s.col("rules").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"order": int(ord)}})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *MongoStore) compactRuleOrder(ctx context.Context) error {
	rules, err := s.ListRules(ctx)
	if err != nil {
		return err
	}
	for i, rule := range rules {
		_, err := s.col("rules").UpdateOne(ctx, bson.M{"_id": rule.ID}, bson.M{"$set": bson.M{"order": i + 1}})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *MongoStore) GetCortexConfig(ctx context.Context) (*models.CortexConfig, error) {
	var cfg models.CortexConfig
	err := s.col("cortex_config").FindOne(ctx, bson.M{}).Decode(&cfg)
	if errors.Is(err, mongo.ErrNoDocuments) {
		cfg = models.CortexConfig{Enabled: false, AutoReply: false, Scope: "global"}
		if _, insertErr := s.col("cortex_config").InsertOne(ctx, cfg); insertErr != nil {
			return nil, insertErr
		}
		return &cfg, nil
	}
	if err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (s *MongoStore) UpdateCortexConfig(ctx context.Context, cfg *models.CortexConfig) error {
	_, err := s.col("cortex_config").UpdateOne(ctx, bson.M{}, bson.M{"$set": cfg}, options.Update().SetUpsert(true))
	return err
}

func (s *MongoStore) ListReplyTemplates(ctx context.Context) ([]models.ReplyTemplate, error) {
	cur, err := s.col("reply_templates").Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var items []models.ReplyTemplate
	if err := cur.All(ctx, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func (s *MongoStore) CreateReplyTemplate(ctx context.Context, item *models.ReplyTemplate) error {
	_, err := s.col("reply_templates").InsertOne(ctx, item)
	return err
}

func (s *MongoStore) UpdateReplyTemplate(ctx context.Context, id string, item *models.ReplyTemplate) error {
	res, err := s.col("reply_templates").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"body": item.Body, "tone": item.Tone, "is_default": item.IsDefault}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) DeleteReplyTemplate(ctx context.Context, id string) error {
	res, err := s.col("reply_templates").DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) ListScheduledPending(ctx context.Context) ([]models.ScheduledMessage, error) {
	cur, err := s.col("scheduled_messages").Find(ctx, bson.M{"status": "pending"})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var items []models.ScheduledMessage
	if err := cur.All(ctx, &items); err != nil {
		return nil, err
	}
	sort.SliceStable(items, func(i, j int) bool { return items[i].ScheduledAt.Before(items[j].ScheduledAt) })
	return items, nil
}

func (s *MongoStore) CreateScheduled(ctx context.Context, item *models.ScheduledMessage) error {
	_, err := s.col("scheduled_messages").InsertOne(ctx, item)
	return err
}

func (s *MongoStore) SetScheduledStatus(ctx context.Context, id, status string) error {
	res, err := s.col("scheduled_messages").UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": bson.M{"status": status}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

func (s *MongoStore) ListCortexActivity(ctx context.Context) ([]models.CortexActivityEntry, error) {
	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: -1}})
	cur, err := s.col("cortex_activity").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var items []models.CortexActivityEntry
	if err := cur.All(ctx, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func (s *MongoStore) AddCortexActivity(ctx context.Context, item *models.CortexActivityEntry) error {
	_, err := s.col("cortex_activity").InsertOne(ctx, item)
	return err
}

func (s *MongoStore) GetProfile(ctx context.Context) (*models.UserProfile, error) {
	var p models.UserProfile
	err := s.col("profile").FindOne(ctx, bson.M{}).Decode(&p)
	if errors.Is(err, mongo.ErrNoDocuments) {
		p = models.UserProfile{ThemeMode: "system", LinkedAccounts: []string{}}
		_, insertErr := s.col("profile").InsertOne(ctx, p)
		if insertErr != nil {
			return nil, insertErr
		}
		return &p, nil
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (s *MongoStore) UpdateProfile(ctx context.Context, p *models.UserProfile) error {
	_, err := s.col("profile").UpdateOne(ctx, bson.M{}, bson.M{"$set": p}, options.Update().SetUpsert(true))
	return err
}

func (s *MongoStore) LogModeSession(ctx context.Context, sess models.ModeSession) error {
	_, err := s.col("mode_sessions").InsertOne(ctx, sess)
	return err
}

func (s *MongoStore) ListFinetuneEvents(ctx context.Context, limit int64) ([]models.FinetuneEvent, error) {
	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: -1}}).SetLimit(limit)
	cur, err := s.col("finetune_events").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var out []models.FinetuneEvent
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *MongoStore) ListNotificationsSince(ctx context.Context, since time.Time) ([]models.Notification, error) {
	cur, err := s.col("notifications").Find(ctx, bson.M{"timestamp": bson.M{"$gte": since}, "deleted": bson.M{"$ne": true}})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var out []models.Notification
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *MongoStore) ListCortexActivitySince(ctx context.Context, since time.Time) ([]models.CortexActivityEntry, error) {
	cur, err := s.col("cortex_activity").Find(ctx, bson.M{"timestamp": bson.M{"$gte": since}})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var out []models.CortexActivityEntry
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *MongoStore) ListModeSessionsSince(ctx context.Context, since time.Time) ([]models.ModeSession, error) {
	cur, err := s.col("mode_sessions").Find(ctx, bson.M{"started_at": bson.M{"$gte": since}})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var out []models.ModeSession
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}
