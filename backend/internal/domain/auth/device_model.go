package auth

import "time"

type DeviceAuthorization struct {
	ID               uint       `gorm:"primaryKey"`
	DeviceCode       string     `gorm:"not null;uniqueIndex"`
	UserCode         string     `gorm:"not null;uniqueIndex"`
	KioskoID         *uint
	TenantID         *uint
	ClaveKioskoPlain *string    `gorm:"column:clave_kiosko_plain"` // temporal; se limpia al canjear el token
	Status           string     `gorm:"not null;default:'pending'"`
	ExpiresAt        time.Time  `gorm:"not null"`
	CreatedAt        time.Time
	DeletedAt        *time.Time `gorm:"index"`
}

func (DeviceAuthorization) TableName() string { return "device_authorizations" }

const (
	DeviceStatusPending  = "pending"
	DeviceStatusApproved = "approved"
	DeviceStatusDenied   = "denied"
)
