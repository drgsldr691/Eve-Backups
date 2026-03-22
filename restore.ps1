param(
    [string]$BACKUP_DIR
)

$ErrorActionPreference = "Stop"

if (-not $BACKUP_DIR) {
    Write-Host "Usage: .\restore.ps1 <backup-folder>"
    exit
}

#############################################
# VALIDATE PATH
#############################################

if (-not (Test-Path $BACKUP_DIR)) {
    Write-Host "Backup folder not found: $BACKUP_DIR"
    exit
}

#############################################
# RESTORE POSTGRES
#############################################

Write-Host "Restoring Postgres..."

$pgTemp = Join-Path $BACKUP_DIR "postgres_temp"
Expand-Archive -Path "$BACKUP_DIR\postgres.zip" -DestinationPath $pgTemp -Force

Get-Content "$pgTemp\postgres.sql" | docker exec -i postgres psql -U postgres

Remove-Item $pgTemp -Recurse -Force

#############################################
# RESTORE NEO4J
#############################################

Write-Host "Restoring Neo4j..."

$neoTemp = Join-Path $BACKUP_DIR "neo4j_temp"
Expand-Archive -Path "$BACKUP_DIR\neo4j.zip" -DestinationPath $neoTemp -Force

docker cp "$neoTemp\neo4j.dump" neo4j:/tmp/neo4j.dump

docker exec neo4j neo4j-admin load --from=/tmp/neo4j.dump --database=neo4j --force

Remove-Item $neoTemp -Recurse -Force

#############################################
# RESTORE QDRANT
#############################################

Write-Host "Restoring Qdrant..."

docker run --rm `
    -v qdrant_storage:/data `
    -v ${BACKUP_DIR}:/backup `
    alpine `
    sh -c "rm -rf /data/* && tar xzf /backup/qdrant.tar.gz -C /data"

#############################################
# DONE
#############################################

Write-Host "Restore complete."