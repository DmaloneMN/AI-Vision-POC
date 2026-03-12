-- OSA (On-Shelf Availability) Database Schema
-- Run this script against the Azure SQL Database: db-osa-poc

-- ============================================================
-- Tables
-- ============================================================

CREATE TABLE dbo.Stores (
    StoreId       INT            NOT NULL IDENTITY(1,1),
    StoreName     NVARCHAR(255)  NOT NULL,
    StoreCode     NVARCHAR(50)   NOT NULL UNIQUE,
    Location      NVARCHAR(500)  NULL,
    CreatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Stores PRIMARY KEY (StoreId)
);

CREATE TABLE dbo.Shelves (
    ShelfId       INT            NOT NULL IDENTITY(1,1),
    StoreId       INT            NOT NULL,
    ShelfCode     NVARCHAR(50)   NOT NULL,
    ShelfName     NVARCHAR(255)  NULL,
    Aisle         NVARCHAR(50)   NULL,
    Section       NVARCHAR(50)   NULL,
    TotalSlots    INT            NOT NULL DEFAULT 0,
    CreatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Shelves PRIMARY KEY (ShelfId),
    CONSTRAINT FK_Shelves_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId)
);

CREATE TABLE dbo.ShelfReadings (
    ReadingId         INT           NOT NULL IDENTITY(1,1),
    ShelfId           INT           NOT NULL,
    StoreId           INT           NOT NULL,
    BlobName          NVARCHAR(500) NOT NULL,
    BlobUrl           NVARCHAR(1000) NULL,
    CapturedAt        DATETIME2     NOT NULL,
    ProcessedAt       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    AvailabilityScore DECIMAL(5,2)  NOT NULL DEFAULT 0,
    FilledSlots       INT           NULL,
    EmptySlots        INT           NULL,
    CONSTRAINT PK_ShelfReadings PRIMARY KEY (ReadingId),
    CONSTRAINT FK_ShelfReadings_Shelves FOREIGN KEY (ShelfId) REFERENCES dbo.Shelves(ShelfId)
);

CREATE TABLE dbo.Predictions (
    PredictionId      INT           NOT NULL IDENTITY(1,1),
    ReadingId         INT           NOT NULL,
    TagName           NVARCHAR(255) NOT NULL,
    Probability       DECIMAL(6,4)  NOT NULL,
    BoundingBoxLeft   DECIMAL(8,6)  NULL,
    BoundingBoxTop    DECIMAL(8,6)  NULL,
    BoundingBoxWidth  DECIMAL(8,6)  NULL,
    BoundingBoxHeight DECIMAL(8,6)  NULL,
    CreatedAt         DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Predictions PRIMARY KEY (PredictionId),
    CONSTRAINT FK_Predictions_ShelfReadings FOREIGN KEY (ReadingId) REFERENCES dbo.ShelfReadings(ReadingId)
);

CREATE TABLE dbo.Alerts (
    AlertId           INT           NOT NULL IDENTITY(1,1),
    ShelfId           INT           NOT NULL,
    StoreId           INT           NOT NULL,
    ReadingId         INT           NOT NULL,
    Severity          NVARCHAR(20)  NOT NULL,  -- 'Critical', 'Warning', 'Info'
    AvailabilityScore DECIMAL(5,2)  NOT NULL,
    Message           NVARCHAR(1000) NULL,
    IsProcessed       BIT           NOT NULL DEFAULT 0,
    CreatedAt         DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    ProcessedAt       DATETIME2     NULL,
    CONSTRAINT PK_Alerts PRIMARY KEY (AlertId),
    CONSTRAINT FK_Alerts_Shelves FOREIGN KEY (ShelfId) REFERENCES dbo.Shelves(ShelfId),
    CONSTRAINT FK_Alerts_ShelfReadings FOREIGN KEY (ReadingId) REFERENCES dbo.ShelfReadings(ReadingId)
);

CREATE TABLE dbo.AlertNotifications (
    NotificationId    INT           NOT NULL IDENTITY(1,1),
    AlertId           INT           NOT NULL,
    Channel           NVARCHAR(50)  NOT NULL,  -- 'Email', 'Teams'
    RecipientAddress  NVARCHAR(500) NULL,
    SentAt            DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    Status            NVARCHAR(20)  NOT NULL DEFAULT 'Sent',
    ErrorMessage      NVARCHAR(1000) NULL,
    CONSTRAINT PK_AlertNotifications PRIMARY KEY (NotificationId),
    CONSTRAINT FK_AlertNotifications_Alerts FOREIGN KEY (AlertId) REFERENCES dbo.Alerts(AlertId)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IX_ShelfReadings_ShelfId_CapturedAt ON dbo.ShelfReadings (ShelfId, CapturedAt DESC);
CREATE INDEX IX_Alerts_IsProcessed_CreatedAt ON dbo.Alerts (IsProcessed, CreatedAt DESC);
CREATE INDEX IX_Alerts_StoreId_Severity ON dbo.Alerts (StoreId, Severity);

-- ============================================================
-- Stored Procedures
-- ============================================================

GO

CREATE PROCEDURE dbo.sp_GetUnprocessedAlerts
    @MaxRecords INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@MaxRecords)
        a.AlertId,
        a.ShelfId,
        a.StoreId,
        a.ReadingId,
        a.Severity,
        a.AvailabilityScore,
        a.Message,
        a.CreatedAt,
        st.StoreName,
        st.StoreCode,
        sh.ShelfCode,
        sh.ShelfName,
        sh.Aisle
    FROM dbo.Alerts a
    INNER JOIN dbo.Stores  st ON st.StoreId = a.StoreId
    INNER JOIN dbo.Shelves sh ON sh.ShelfId = a.ShelfId
    WHERE a.IsProcessed = 0
    ORDER BY
        CASE a.Severity
            WHEN 'Critical' THEN 1
            WHEN 'Warning'  THEN 2
            ELSE 3
        END,
        a.CreatedAt ASC;
END;

GO

CREATE PROCEDURE dbo.sp_MarkAlertProcessed
    @AlertId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Alerts
    SET
        IsProcessed = 1,
        ProcessedAt = GETUTCDATE()
    WHERE AlertId = @AlertId;
END;

GO
