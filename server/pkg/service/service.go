package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"net"
	"os"
	"time"

	jwt "github.com/form3tech-oss/jwt-go"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/model"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/harehare/textusm/pkg/values"
	uuid "github.com/satori/go.uuid"
)

var (
	encryptKey      = []byte(os.Getenv("ENCRYPT_KEY"))
	shareEncryptKey = []byte(os.Getenv("SHARE_ENCRYPT_KEY"))
	pubKey          = os.Getenv("ENCRYPT_PUBLIC_KEY")
	priKey          = os.Getenv("ENCRYPT_PRIVATE_KEY")
)

type Service struct {
	repo      repository.ItemRepository
	shareRepo repository.ShareRepository
	userRepo  repository.UserRepository
}

func NewService(r repository.ItemRepository, s repository.ShareRepository, u repository.UserRepository) *Service {
	return &Service{
		repo:      r,
		shareRepo: s,
		userRepo:  u,
	}
}

func isAuthenticated(ctx context.Context) error {
	userID := values.GetUID(ctx)

	if userID == nil {
		return e.NoAuthorizationError(errors.New("not authorization"))
	}

	return nil
}

func (s *Service) FindDiagrams(ctx context.Context, offset, limit int, isPublic bool) ([]*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	items, err := s.repo.Find(ctx, *userID, offset, limit, isPublic)

	if err != nil {
		return nil, err
	}

	resultItems := make([]*item.Item, len(items))

	for i, item := range items {
		if item.Text != "" {
			text, err := Decrypt(encryptKey, item.Text)
			if err != nil {
				return nil, e.DecryptionFailedError(err)
			}
			item.Text = text
		}

		resultItems[i] = item
	}

	return resultItems, nil
}

func (s *Service) FindDiagram(ctx context.Context, itemID string, isPublic bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	item, err := s.repo.FindByID(ctx, *userID, itemID, isPublic)

	if err != nil {
		return nil, err
	}

	text, err := Decrypt(encryptKey, item.Text)

	if err != nil {
		return nil, e.DecryptionFailedError(err)
	}

	item.Text = text
	return item, nil
}

func (s *Service) SaveDiagram(ctx context.Context, item *item.Item, isPublic bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	currentText := item.Text
	text, err := Encrypt(encryptKey, item.Text)

	if err != nil {
		return nil, e.EncryptionFailedError(err)
	}

	item.Text = text
	item.IsPublic = isPublic

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, item.ID, *userID)

		if !isOwner {
			return nil, e.NoAuthorizationError(err)
		}
		_, err = s.repo.Save(ctx, *userID, item, true)

		if err != nil {
			return nil, err
		}

	} else if item.ID != "" {
		_, err := s.repo.FindByID(ctx, *userID, item.ID, true)

		if err == nil || e.GetCode(err) != e.NotFound {
			err := s.repo.Delete(ctx, *userID, item.ID, true)

			if err != nil {
				return nil, err
			}
		}
	}

	resultItem, err := s.repo.Save(ctx, *userID, item, false)
	item.Text = currentText
	resultItem.IsPublic = isPublic

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	userID := values.GetUID(ctx)
	shareID, err := itemIDToShareID(itemID)

	if err != nil {
		return err
	}

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, itemID, *userID)

		if !isOwner {
			return e.NoAuthorizationError(err)
		}
	}

	if isPublic {
		if err := s.repo.Delete(ctx, *userID, itemID, true); err != nil {
			return err
		}
	}

	if err := s.shareRepo.Delete(ctx, *shareID); err != nil {
		return err
	}

	return s.repo.Delete(ctx, *userID, itemID, false)
}

func (s *Service) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	diagramItem, err := s.FindDiagram(ctx, itemID, false)

	if err != nil {
		return nil, err
	}
	diagramItem.IsBookmark = isBookmark
	return s.SaveDiagram(ctx, diagramItem, false)
}

func (s *Service) FindShareItem(ctx context.Context, token string, password string) (*item.Item, error) {
	t, err := base64.RawURLEncoding.DecodeString(token)

	if err != nil {
		return nil, err
	}

	jwtToken, err := verifyToken(ctx, string(t))

	if err != nil {
		return nil, err
	}

	claims := jwtToken.Claims.(jwt.MapClaims)
	item, shareInfo, err := s.shareRepo.Find(ctx, claims["sub"].(string))

	if err != nil {
		return nil, err
	}

	ip := values.GetIP(ctx)

	if ip == nil || !shareInfo.CheckIpWithinRange(*ip) {
		return nil, e.ForbiddenError(errors.New("not allow ip address"))
	}

	uid := values.GetUID(ctx)
	var email string

	if uid != nil {
		u, err := s.userRepo.Find(ctx, *uid)
		if err != nil {
			return nil, e.ForbiddenError(errors.New("sign in required"))
		}
		email = u.Email
	}

	if !shareInfo.ValidEmail(email) {
		return nil, e.ForbiddenError(errors.New("not allow email"))
	}

	if claims["check_password"].(bool) {
		if password == "" {
			return nil, e.ForbiddenError(errors.New("password is required"))
		}

		if err := shareInfo.ComparePassword(password); err != nil {
			return nil, e.ForbiddenError(err)
		}
	}

	text, err := Decrypt(encryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	return item, nil
}

func (s *Service) FindShareCondition(ctx context.Context, itemID string) (*item.ShareCondition, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)

	if userID == nil {
		return nil, e.NoAuthorizationError(errors.New("not authorization"))
	}

	_, err := s.repo.FindByID(ctx, *userID, itemID, false)

	if err != nil {
		return nil, err
	}

	shareID, err := itemIDToShareID(itemID)

	if err != nil {
		return nil, err
	}

	_, share, err := s.shareRepo.Find(ctx, *shareID)

	if err != nil {
		return nil, nil
	}

	return &item.ShareCondition{
		Token:          share.Token,
		UsePassword:    share.Password != "",
		ExpireTime:     int(share.ExpireTime),
		AllowIPList:    share.AllowIPList,
		AllowEmailList: share.AllowEmailList,
	}, nil
}

func (s *Service) Share(ctx context.Context, itemID string, expSecond int, password string, allowIPList []string, allowEmailList []string) (*string, error) {
	userID := values.GetUID(ctx)

	if userID == nil {
		return nil, e.NoAuthorizationError(errors.New("not authorization"))
	}

	item, err := s.repo.FindByID(ctx, *userID, itemID, false)

	if err != nil {
		return nil, err
	}

	shareID, err := itemIDToShareID(item.ID)

	if err != nil {
		return nil, err
	}

	privateKey, err := base64.StdEncoding.DecodeString(priKey)

	if err != nil {
		return nil, err
	}

	signKey, err := jwt.ParseRSAPrivateKeyFromPEM(privateKey)

	if err != nil {
		return nil, err
	}

	now := time.Now()
	expireTime := now.Add(time.Second * time.Duration(expSecond)).Unix()
	token := jwt.New(jwt.SigningMethodRS512)
	claims := token.Claims.(jwt.MapClaims)
	claims["jti"] = uuid.NewV4().String()
	claims["sub"] = shareID
	claims["iat"] = now.Unix()
	claims["exp"] = expireTime
	claims["check_password"] = password != ""
	claims["check_email"] = len(allowEmailList) > 0

	tokenString, err := token.SignedString(signKey)

	if err != nil {
		return nil, err
	}

	shareInfo := model.Share{
		Token:          tokenString,
		Password:       password,
		AllowIPList:    validIpList(allowIPList),
		AllowEmailList: allowEmailList,
		ExpireTime:     expireTime * int64(1000),
	}

	if err := s.shareRepo.Save(ctx, *shareID, item, &shareInfo); err != nil {
		return nil, err
	}

	base64Token := base64.RawURLEncoding.EncodeToString([]byte(tokenString))

	return &base64Token, nil
}

func verifyToken(ctx context.Context, token string) (*jwt.Token, error) {
	publicKey, err := base64.StdEncoding.DecodeString(pubKey)

	if err != nil {
		return nil, e.ForbiddenError(err)
	}

	jwtPublicKey, err := jwt.ParseRSAPublicKeyFromPEM(publicKey)
	if err != nil {
		return nil, e.ForbiddenError(err)
	}

	verifiedToken, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, err
		}
		return jwtPublicKey, nil
	})

	if err != nil || !verifiedToken.Valid {
		return nil, e.URLExpiredError(err)
	}

	return verifiedToken, nil
}

func (s *Service) isPublicDiagramOwner(ctx context.Context, itemID, ownerUserID string) (bool, error) {
	if itemID == "" {
		return true, nil
	}

	_, err := s.repo.FindByID(ctx, ownerUserID, itemID, false)
	isOwner := err == nil

	if e.GetCode(err) == e.NotFound {
		return isOwner, nil
	}

	return isOwner, err
}

func itemIDToShareID(itemID string) (*string, error) {
	mac := hmac.New(sha256.New, shareEncryptKey)
	_, err := mac.Write([]byte(itemID))

	if err != nil {
		return nil, err
	}

	hashKey := hex.EncodeToString(mac.Sum(nil))
	return &hashKey, nil
}

func validIpList(ipList []string) []string {
	allowIpList := []string{}
	for _, ip := range ipList {
		p := net.ParseIP(ip)
		if p != nil {
			allowIpList = append(allowIpList, ip)
			continue
		}

		_, _, err := net.ParseCIDR(ip)

		if err != nil {
			continue
		}

		allowIpList = append(allowIpList, ip)
	}
	return allowIpList
}
