package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"net"
	"os"
	"slices"
	"time"

	"log/slog"

	"github.com/99designs/gqlgen/graphql"
	jwt "github.com/form3tech-oss/jwt-go"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	shareModel "github.com/harehare/textusm/internal/domain/model/share"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	shareRepo "github.com/harehare/textusm/internal/domain/repository/share"
	userRepo "github.com/harehare/textusm/internal/domain/repository/user"
	e "github.com/harehare/textusm/internal/error"
	"github.com/harehare/textusm/internal/github"
	"github.com/samber/mo"
	uuid "github.com/satori/go.uuid"
)

var (
	shareEncryptKey = []byte(os.Getenv("SHARE_ENCRYPT_KEY"))
	pubKey          = os.Getenv("ENCRYPT_PUBLIC_KEY")
	priKey          = os.Getenv("ENCRYPT_PRIVATE_KEY")
)

type Service struct {
	repo         itemRepo.ItemRepository
	shareRepo    shareRepo.ShareRepository
	userRepo     userRepo.UserRepository
	transaction  db.Transaction
	clientID     github.ClientID
	clientSecret github.ClientSecret
}

func NewService(r itemRepo.ItemRepository, s shareRepo.ShareRepository, u userRepo.UserRepository, transaction db.Transaction, clientID github.ClientID, clientSecret github.ClientSecret) *Service {
	return &Service{
		repo:         r,
		shareRepo:    s,
		userRepo:     u,
		transaction:  transaction,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func isAuthenticated(ctx context.Context) error {
	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return e.NoAuthorizationError(e.ErrNotAuthorization)
	}

	return nil
}

func (s *Service) Find(ctx context.Context, offset, limit int, isPublic bool, isBookmark bool, fields map[string]struct{}) mo.Result[[]*diagramitem.DiagramItem] {
	var items []*diagramitem.DiagramItem

	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		shouldLoadText := slices.Contains(graphql.CollectAllFields(ctx), "text")

		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		result := s.repo.Find(ctx, values.GetUID(ctx).OrEmpty(), offset, limit, isPublic, isBookmark, shouldLoadText)

		if !result.IsError() {
			items = result.MustGet()
		}
		return result.Error()
	})

	if err != nil {
		return mo.Err[[]*diagramitem.DiagramItem](err)
	}

	return mo.Ok(items)
}

func (s *Service) FindByID(ctx context.Context, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	var item *diagramitem.DiagramItem

	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		result := s.repo.FindByID(ctx, values.GetUID(ctx).OrEmpty(), itemID, isPublic)

		if !result.IsError() {
			item = result.MustGet()
		}

		return result.Error()
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (s *Service) Save(ctx context.Context, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		slog.Debug("Save diagram", "ID", item.ID(), "isPublic", isPublic)
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)

		if isPublic {
			publishItem := item.Publish()
			ret := s.isPublicDiagramOwner(ctx, publishItem.ID(), userID.OrEmpty())

			if !ret.OrElse(false) {
				return ret.Error()
			}

			return s.repo.Save(ctx, userID.OrEmpty(), item, true).Error()
		} else {
			ret := s.repo.FindByID(ctx, userID.OrEmpty(), item.ID(), true)

			if ret.IsOk() {
				err := s.repo.Delete(ctx, userID.OrEmpty(), item.ID(), true)

				if err.IsError() {
					return err.Error()
				}
				slog.Debug("Delete public diagram", "ID", item.ID())
			}
		}

		return s.repo.Save(ctx, userID.OrEmpty(), item, false).Error()
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (s *Service) Delete(ctx context.Context, itemID string, isPublic bool) error {
	return s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)
		shareID := itemIDToShareID(itemID)

		if shareID.IsError() {
			return shareID.Error()
		}

		if isPublic {
			ret := s.isPublicDiagramOwner(ctx, itemID, userID.OrEmpty())

			if !ret.OrElse(false) {
				return e.NoAuthorizationError(e.ErrNotDiagramOwner)
			}
			if err := s.repo.Delete(ctx, userID.OrEmpty(), itemID, true); err.IsError() {
				return err.Error()
			}
		}

		if err := s.shareRepo.Delete(ctx, userID.OrEmpty(), shareID.OrEmpty()); err.IsError() {
			return err.Error()
		}

		return s.repo.Delete(ctx, userID.OrEmpty(), itemID, false).Error()
	})
}

func (s *Service) Bookmark(ctx context.Context, itemID string, isBookmark bool) mo.Result[*diagramitem.DiagramItem] {
	var item *diagramitem.DiagramItem
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		result := s.FindByID(ctx, itemID, false).FlatMap(func(item *diagramitem.DiagramItem) mo.Result[*diagramitem.DiagramItem] {
			return s.Save(ctx, item.Bookmark(isBookmark), false)
		})

		if !result.IsError() {
			item = result.MustGet()
		}

		return result.Error()
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (s *Service) FindShareItem(ctx context.Context, token string, password string) mo.Result[*diagramitem.DiagramItem] {
	var item *diagramitem.DiagramItem
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		t, err := base64.RawURLEncoding.DecodeString(token)

		if err != nil {
			return err
		}

		jwtTokenResult := verifyToken(string(t))

		if jwtTokenResult.IsError() {
			return jwtTokenResult.Error()
		}

		jwtToken, _ := jwtTokenResult.Get()
		claims := jwtToken.Claims.(jwt.MapClaims)
		shareResponse := s.shareRepo.Find(ctx, claims["sub"].(string))

		if shareResponse.IsError() {
			return shareResponse.Error()
		}

		ip := values.GetIP(ctx)
		shareInfo := shareResponse.OrEmpty().ShareInfo

		if ip.IsAbsent() || !shareInfo.CheckIpWithinRange(ip.OrEmpty()) {
			return e.ForbiddenError(e.ErrNotAllowIpAddress)
		}

		uid := values.GetUID(ctx)

		if uid.IsPresent() {
			u := s.userRepo.Find(ctx, uid.OrEmpty())
			if u.IsError() {
				return e.ForbiddenError(e.ErrSignInRequired)
			}

			uu, _ := u.Get()

			if !shareInfo.ValidEmail(uu.Email) {
				return e.ForbiddenError(e.ErrNotAllowEmail)
			}
		}

		if claims["check_password"].(bool) {
			if password == "" {
				return e.ForbiddenError(e.ErrPasswordIsRequired)
			}

			if err := shareInfo.ComparePassword(password); err != nil {
				return e.ForbiddenError(err)
			}
		}

		item = shareResponse.OrEmpty().DiagramItem
		return nil
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (s *Service) FindShareCondition(ctx context.Context, itemID string) mo.Result[*shareModel.ShareCondition] {
	var shareCondition *shareModel.ShareCondition
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)

		if userID.IsAbsent() {
			return e.NoAuthorizationError(e.ErrNotAuthorization)
		}

		ret := s.repo.FindByID(ctx, userID.OrEmpty(), itemID, false)

		if ret.IsError() {
			return ret.Error()
		}

		shareID := itemIDToShareID(itemID)

		if shareID.IsError() {
			return shareID.Error()
		}

		shareResponse := s.shareRepo.Find(ctx, shareID.OrEmpty())

		if shareResponse.OrEmpty().ShareInfo == nil || shareResponse.IsError() {
			// TODO:
			return nil
		}

		share := shareResponse.OrEmpty().ShareInfo

		shareCondition = &shareModel.ShareCondition{
			Token:          share.Token,
			UsePassword:    share.Password != "",
			ExpireTime:     int(share.ExpireTime),
			AllowIPList:    share.AllowIPList,
			AllowEmailList: share.AllowEmailList,
		}

		return nil
	})

	if err != nil {
		return mo.Err[*shareModel.ShareCondition](err)
	}

	return mo.Ok(shareCondition)
}

func (s *Service) Share(ctx context.Context, itemID string, expSecond int, password string, allowIPList []string, allowEmailList []string) mo.Result[string] {
	var shareToken string
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		userID := values.GetUID(ctx)

		if userID.IsAbsent() {
			return e.NoAuthorizationError(e.ErrNotAuthorization)
		}

		itemResult := s.repo.FindByID(ctx, userID.OrEmpty(), itemID, false)

		if itemResult.IsError() {
			return itemResult.Error()
		}

		item := itemResult.OrEmpty()
		shareID := itemIDToShareID(item.ID())

		if shareID.IsError() {
			return shareID.Error()
		}

		privateKey, err := base64.StdEncoding.DecodeString(priKey)

		if err != nil {
			return err
		}

		signKey, err := jwt.ParseRSAPrivateKeyFromPEM(privateKey)

		if err != nil {
			return err
		}

		now := time.Now()
		expireTime := now.Add(time.Second * time.Duration(expSecond)).Unix()
		token := jwt.New(jwt.SigningMethodRS512)
		claims := token.Claims.(jwt.MapClaims)
		claims["jti"] = uuid.NewV4().String()
		claims["sub"] = shareID.OrEmpty()
		claims["iat"] = now.Unix()
		claims["exp"] = expireTime
		claims["check_password"] = password != ""
		claims["check_email"] = len(allowEmailList) > 0

		tokenString, err := token.SignedString(signKey)

		if err != nil {
			return err
		}

		shareInfo := shareModel.Share{
			Token:          tokenString,
			Password:       password,
			AllowIPList:    validIpList(allowIPList),
			AllowEmailList: allowEmailList,
			ExpireTime:     expireTime * int64(1000),
		}

		if err := s.shareRepo.Save(ctx, userID.OrEmpty(), shareID.OrEmpty(), item, &shareInfo); err.IsError() {
			return err.Error()
		}

		shareToken = base64.RawURLEncoding.EncodeToString([]byte(tokenString))
		return nil
	})

	if err != nil {
		return mo.Err[string](err)
	}

	return mo.Ok(shareToken)
}

func (s *Service) RevokeToken(ctx context.Context, accessToken string) error {
	return s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		return s.userRepo.RevokeToken(ctx, string(s.clientID), string(s.clientSecret), accessToken)
	})
}

func verifyToken(token string) mo.Result[*jwt.Token] {
	publicKey, err := base64.StdEncoding.DecodeString(pubKey)

	if err != nil {
		return mo.Err[*jwt.Token](e.ForbiddenError(err))
	}

	jwtPublicKey, err := jwt.ParseRSAPublicKeyFromPEM(publicKey)
	if err != nil {
		return mo.Err[*jwt.Token](e.ForbiddenError(err))
	}

	verifiedToken, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, err
		}
		return jwtPublicKey, nil
	})

	if err != nil || !verifiedToken.Valid {
		return mo.Err[*jwt.Token](e.URLExpiredError(err))
	}

	return mo.Ok(verifiedToken)
}

func (s *Service) isPublicDiagramOwner(ctx context.Context, itemID string, ownerUserID string) mo.Result[bool] {
	if itemID == "" {
		return mo.Ok(true)
	}

	ret := s.repo.FindByID(ctx, ownerUserID, itemID, false)
	isOwner := ret.IsOk()

	if e.GetCode(ret.Error()) == e.NotFound {
		return mo.Ok(isOwner)
	}

	return mo.Ok(isOwner)
}

func itemIDToShareID(itemID string) mo.Result[string] {
	mac := hmac.New(sha256.New, shareEncryptKey)
	_, err := mac.Write([]byte(itemID))

	if err != nil {
		return mo.Err[string](err)
	}

	return mo.Ok(hex.EncodeToString(mac.Sum(nil)))
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
