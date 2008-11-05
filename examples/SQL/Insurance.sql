CREATE TABLE Asset (
	AssetID	int NOT NULL,
	VehicleColour	varchar NULL,
	VehicleDealerID	int NULL,
	VehicleEngineNumber	varchar NULL,
	VehicleFinanceInstitutionID	int NULL,
	VehicleHasCommercialRegistration	bit NULL,
	VehicleModelYearNr	int NULL,
	VehicleRegistrationNr	FixedLengthText(8) NULL,
	VehicleVIN	int NULL,
	VehicleVehicleTypeBadge	varchar NULL,
	VehicleVehicleTypeMake	varchar NULL,
	VehicleVehicleTypeModel	varchar NULL,
	UNIQUE(AssetID)
)
GO

CREATE TABLE Claim (
	ClaimID	int NOT NULL,
	IncidentAddressCity	varchar NULL,
	IncidentAddressPostcode	varchar NULL,
	IncidentAddressStateCode	UnsignedTinyInteger(32) NULL,
	IncidentAddressStreet	varchar(256) NULL,
	IncidentDateTime	DateAndTime NULL,
	IncidentDateTime	DateAndTime NULL,
	IncidentName	varchar(256) NULL,
	IncidentOfficerName	varchar(256) NULL,
	IncidentPoliceReportNr	int NULL,
	IncidentStationName	varchar(256) NULL,
	LodgementDateTime	DateAndTime NULL,
	LodgementPersonID	int NOT NULL,
	P_sequence	int NOT NULL,
	PolicyP_productCode	UnsignedTinyInteger(32) NOT NULL,
	PolicyP_serial	int NOT NULL,
	PolicyP_stateCode	UnsignedTinyInteger(32) NOT NULL,
	PolicyP_yearNr	int NOT NULL,
	VehicleIncidentDescription	varchar(1024) NULL,
	VehicleIncidentDrivingBloodTestResult	varchar NULL,
	VehicleIncidentDrivingBreathTestResult	varchar NULL,
	VehicleIncidentDrivingCharge	varchar NULL,
	VehicleIncidentDrivingDriverID	int NULL,
	VehicleIncidentDrivingHospitalName	varchar(256) NULL,
	VehicleIncidentDrivingIntoxication	varchar NULL,
	VehicleIncidentDrivingIsWarning	bit NULL,
	VehicleIncidentDrivingNonconsentReason	varchar NULL,
	VehicleIncidentDrivingUnlicensedReason	varchar NULL,
	VehicleIncidentLossTypeCode	FixedLengthText NULL,
	VehicleIncidentPrevious_damageDescription	varchar(1024) NULL,
	VehicleIncidentReason	varchar NULL,
	VehicleIncidentTowedLocation	varchar NULL,
	VehicleIncidentWeatherDescription	varchar(1024) NULL,
	UNIQUE(ClaimID)
)
GO

CREATE TABLE ContractorAppointment (
	ClaimID	int NOT NULL,
	ContractorID	int NOT NULL,
	UNIQUE(ClaimID, ContractorID)
)
GO

CREATE TABLE Cover (
	AssetID	int NOT NULL,
	CoverTypeCode	FixedLengthText NOT NULL,
	PolicyP_productCode	UnsignedTinyInteger(32) NOT NULL,
	PolicyP_serial	int NOT NULL,
	PolicyP_stateCode	UnsignedTinyInteger(32) NOT NULL,
	PolicyP_yearNr	int NOT NULL,
	UNIQUE(PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial, AssetID, CoverTypeCode)
)
GO

CREATE TABLE CoverType (
	CoverTypeCode	FixedLengthText NOT NULL,
	CoverTypeName	varchar NOT NULL,
	UNIQUE(CoverTypeCode)
)
GO

CREATE TABLE CoverWording (
	CoverTypeCode	FixedLengthText NOT NULL,
	PolicyWordingText	LargeLengthText NOT NULL,
	StartDate	datetime NOT NULL,
	UNIQUE(CoverTypeCode, PolicyWordingText, StartDate)
)
GO

CREATE TABLE DamagedProperty (
	AddressCity	varchar NOT NULL,
	AddressPostcode	varchar NULL,
	AddressStateCode	UnsignedTinyInteger(32) NULL,
	AddressStreet	varchar(256) NOT NULL,
	IncidentClaimID	int NULL,
	OwnerName	varchar(256) NULL,
	PhoneNr	varchar NULL,
	UNIQUE(IncidentClaimID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode)
)
GO

CREATE TABLE DemeritKind (
	DemeritKindName	varchar NOT NULL,
	UNIQUE(DemeritKindName)
)
GO

CREATE TABLE LossType (
	LossTypeCode	FixedLengthText NOT NULL,
	InvolvesDriving	bit NOT NULL,
	IsSingleVehicleIncident	bit NOT NULL,
	LiabilityCode	FixedLengthText(1) NULL,
	UNIQUE(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	IncidentClaimID	int NOT NULL,
	LostItemNr	int NOT NULL,
	Description	varchar(1024) NOT NULL,
	PurchaseDate	datetime NULL,
	PurchasePlace	varchar NULL,
	PurchasePrice	decimal(18, 2) NULL,
	UNIQUE(IncidentClaimID, LostItemNr)
)
GO

CREATE TABLE Party (
	PartyID	int NOT NULL,
	CompanyContactPersonID	int NULL,
	DriverIsInternational	bit NULL,
	DriverLicenseNumber	varchar NULL,
	DriverLicenseType	varchar NULL,
	DriverYearNr	int NULL,
	IsACompany	bit NOT NULL,
	PersonAddressCity	varchar NULL,
	PersonAddressPostcode	varchar NULL,
	PersonAddressStateCode	UnsignedTinyInteger(32) NULL,
	PersonAddressStreet	varchar(256) NULL,
	PersonBirthDate	datetime NULL,
	PersonBusinessPhoneNr	varchar NULL,
	PersonContactTime	Time NULL,
	PersonEmail	varchar NULL,
	PersonFamilyName	varchar(256) NULL,
	PersonGivenName	varchar(256) NULL,
	PersonHomePhoneNr	varchar NULL,
	PersonMobilePhoneNr	varchar NULL,
	PersonOccupation	varchar NULL,
	PersonPreferredContactMethod	FixedLengthText(1) NULL,
	PersonTitle	varchar NULL,
	PostalAddressCity	varchar NULL,
	PostalAddressPostcode	varchar NULL,
	PostalAddressStateCode	UnsignedTinyInteger(32) NULL,
	PostalAddressStreet	varchar(256) NULL,
	UNIQUE(PartyID)
)
GO

CREATE TABLE Policy (
	P_productCode	UnsignedTinyInteger(32) NOT NULL,
	P_serial	int NOT NULL,
	P_stateCode	UnsignedTinyInteger(32) NOT NULL,
	P_yearNr	int NOT NULL,
	ApplicationNr	int NOT NULL,
	AuthorisedRepID	int NULL,
	ClientID	int NOT NULL,
	ITCClaimed	decimal(18, 2) NULL,
	UNIQUE(P_yearNr, P_productCode, P_stateCode, P_serial)
)
GO

CREATE TABLE Product (
	ProductCode	UnsignedTinyInteger(32) NOT NULL,
	Alias	FixedLengthText(3) NULL,
	ProdDescription	varchar(80) NULL,
	UNIQUE(ProductCode)
)
GO

CREATE TABLE State (
	StateCode	UnsignedTinyInteger(32) NOT NULL,
	StateName	varchar(256) NULL,
	UNIQUE(StateCode)
)
GO

CREATE TABLE ThirdParty (
	PersonID	int NOT NULL,
	VehicleIncidentClaimID	int NOT NULL,
	InsurerID	int NULL,
	ModelYearNr	int NULL,
	VehicleRegistrationNr	FixedLengthText(8) NULL,
	VehicleTypeBadge	varchar NULL,
	VehicleTypeMake	varchar NULL,
	VehicleTypeModel	varchar NULL,
	UNIQUE(PersonID, VehicleIncidentClaimID)
)
GO

CREATE TABLE UnderwritingDemerit (
	DemeritKindName	varchar NOT NULL,
	VehicleIncidentClaimID	int NOT NULL,
	OccurrenceCount	int NULL,
	UNIQUE(VehicleIncidentClaimID, DemeritKindName)
)
GO

CREATE TABLE Witness (
	IncidentClaimID	int NOT NULL,
	Name	varchar(256) NOT NULL,
	AddressCity	varchar NULL,
	AddressPostcode	varchar NULL,
	AddressStateCode	UnsignedTinyInteger(32) NULL,
	AddressStreet	varchar(256) NULL,
	ContactPhoneNr	varchar NULL,
	UNIQUE(IncidentClaimID, Name)
)
GO

