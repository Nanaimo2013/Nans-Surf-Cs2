#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define DATABASE_VERSION 1
#define MAX_MAP_NAME 128
#define MAX_STEAMID_LENGTH 32

enum struct PlayerRecord {
    char SteamID[MAX_STEAMID_LENGTH];
    float BestTime;
    int Rank;
    int Points;
}

enum struct MapRecord {
    char MapName[MAX_MAP_NAME];
    float WorldRecord;
    char WorldRecordHolder[MAX_STEAMID_LENGTH];
    ArrayList StageRecords;
    ArrayList BonusRecords;
}

methodmap SurfDatabase {
    public SurfDatabase() {
        this.CreateDatabaseDirectories();
        this.EnsureDatabaseVersion();
    }

    public void CreateDatabaseDirectories() {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "data/surftimer");
        if (!DirExists(path)) {
            CreateDirectory(path, 511);
        }

        // Create subdirectories
        char subpaths[][] = {
            "players",
            "maps",
            "records",
            "stages",
            "bonuses"
        };

        for (int i = 0; i < sizeof(subpaths); i++) {
            Format(path, sizeof(path), "data/surftimer/%s", subpaths[i]);
            BuildPath(Path_SM, path, sizeof(path));
            if (!DirExists(path)) {
                CreateDirectory(path, 511);
            }
        }
    }

    public void EnsureDatabaseVersion() {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "data/surftimer/version.txt");

        if (!FileExists(path)) {
            File versionFile = OpenFile(path, "w");
            if (versionFile != null) {
                WriteFileLine(versionFile, "%d", DATABASE_VERSION);
                CloseHandle(versionFile);
            }
        }
    }

    public bool SavePlayerRecord(const char[] steamId, const char[] mapName, float time, int style) {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "data/surftimer/records/%s_%s_%d.txt", steamId, mapName, style);

        File recordFile = OpenFile(path, "w");
        if (recordFile == null) {
            LogError("Failed to open record file: %s", path);
            return false;
        }

        WriteFileLine(recordFile, "SteamID: %s", steamId);
        WriteFileLine(recordFile, "Map: %s", mapName);
        WriteFileLine(recordFile, "Time: %.2f", time);
        WriteFileLine(recordFile, "Style: %d", style);
        WriteFileLine(recordFile, "Timestamp: %d", GetTime());

        CloseHandle(recordFile);
        return true;
    }

    public float GetPersonalBest(const char[] steamId, const char[] mapName, int style) {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "data/surftimer/records/%s_%s_%d.txt", steamId, mapName, style);

        if (!FileExists(path)) {
            return 0.0;
        }

        File recordFile = OpenFile(path, "r");
        if (recordFile == null) {
            return 0.0;
        }

        char buffer[256];
        float bestTime = 0.0;
        while (!recordFile.EndOfFile() && recordFile.ReadLine(buffer, sizeof(buffer))) {
            if (StrContains(buffer, "Time:") != -1) {
                ReplaceString(buffer, sizeof(buffer), "Time: ", "");
                bestTime = StringToFloat(buffer);
                break;
            }
        }

        CloseHandle(recordFile);
        return bestTime;
    }

    public ArrayList GetTopTimes(const char[] mapName, int style, int limit = 10) {
        ArrayList topTimes = new ArrayList(sizeof(PlayerRecord));
        char recordsDir[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, recordsDir, sizeof(recordsDir), "data/surftimer/records");

        DirectoryListing dir = OpenDirectory(recordsDir);
        if (dir == null) {
            return topTimes;
        }

        char fileName[256];
        FileType fileType;
        while (dir.GetNext(fileName, sizeof(fileName), fileType)) {
            if (fileType != FileType_File) continue;

            // Check if filename matches map and style
            if (StrContains(fileName, mapName) != -1 && StrContains(fileName, "_"+style+".txt") != -1) {
                char fullPath[PLATFORM_MAX_PATH];
                Format(fullPath, sizeof(fullPath), "%s/%s", recordsDir, fileName);

                File recordFile = OpenFile(fullPath, "r");
                if (recordFile != null) {
                    PlayerRecord record;
                    char buffer[256];
                    while (!recordFile.EndOfFile() && recordFile.ReadLine(buffer, sizeof(buffer))) {
                        if (StrContains(buffer, "SteamID:") != -1) {
                            strcopy(record.SteamID, sizeof(record.SteamID), buffer[9]);
                        }
                        if (StrContains(buffer, "Time:") != -1) {
                            record.BestTime = StringToFloat(buffer[6]);
                        }
                    }
                    CloseHandle(recordFile);

                    // Insert into sorted list
                    int index = 0;
                    while (index < topTimes.Length && topTimes.Get(index, PlayerRecord::BestTime) < record.BestTime) {
                        index++;
                    }
                    topTimes.ShiftUp(index);
                    topTimes.SetArray(index, record);

                    // Limit to top times
                    if (topTimes.Length > limit) {
                        topTimes.Resize(limit);
                    }
                }
            }
        }

        CloseHandle(dir);
        return topTimes;
    }
}

// Global database instance
SurfDatabase g_SurfDatabase; 