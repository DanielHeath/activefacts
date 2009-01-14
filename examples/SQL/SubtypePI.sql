CREATE TABLE Entrant (
	-- Entrant has EntrantID,
	EntrantID                               int IDENTITY NOT NULL,
	-- maybe Competitor is a subtype of Entrant and Competitor has FamilyName,
	CompetitorFamilyName                    varchar NULL,
	-- maybe Team is a subtype of Entrant and Team has TeamID,
	TeamID                                  int NULL,
	PRIMARY KEY(EntrantID)
)
GO

CREATE VIEW dbo.TeamInEntrant_ID (TeamID) WITH SCHEMABINDING AS
	SELECT TeamID FROM dbo.Entrant
	WHERE	TeamID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_TeamInEntrant ON dbo.TeamInEntrant_ID(TeamID)
GO

CREATE VIEW dbo.CompetitorInEntrant_FamilyName (CompetitorFamilyName) WITH SCHEMABINDING AS
	SELECT CompetitorFamilyName FROM dbo.Entrant
	WHERE	CompetitorFamilyName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX FamilyAndGivenNamesAreUnique ON dbo.CompetitorInEntrant_FamilyName(CompetitorFamilyName)
GO

CREATE TABLE EntrantHasGivenName (
	-- EntrantHasGivenName is where Entrant has GivenName and Entrant has EntrantID,
	EntrantID                               int NOT NULL,
	-- EntrantHasGivenName is where Entrant has GivenName,
	GivenName                               varchar NOT NULL,
	PRIMARY KEY(EntrantID, GivenName),
	UNIQUE(GivenName),
	FOREIGN KEY (EntrantID) REFERENCES Entrant (EntrantID)
)
GO

