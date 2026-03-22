param(
    [string]$BACKUP_DIR
)

if (-not $BACKUP_DIR) {
    Write-Host "Usage: .\restore.ps1 <backup-folder>"
    exit
}

#############################################
# RESTORE POSTGRES
#############################################

Write-Host "Restoring Postgres..."
Expand-Archive "$BACKUP_DIR\postgres.zip" "$BACKUP_DIR\postgres_temp"

Get-Content "$BACKUP_DIR\postgres_temp\postgres.sql" |
    docker exec -i postgres psql -U postgres

#############################################
# RESTORE NEO4J
#############################################

Write-Host "Restoring Neo4j..."
Expand-Archive "$BACKUP_DIR\neo4j.zip" "$BACKUP_DIR\neo4j_temp"

docker cp "$BACKUP_DIR\neo4j_temp\neo4j.dump" neo4j:/tmp/
docker exec neo4j neo4j-admin load --from=/tmp/neo4j.dump --database=neo4j --force

#############################################
# RESTORE QDRANT
#############################################

Write-Host "Restoring Qdrant..."
docker run --rm `
    -v qdrant_storage:/data `
    -v ${BACKUP_DIR}:/backup `
    alpine `
    sh -c "rm -rf /data/* && tar xzf /backup/qdrant.tar.gz -C /data"

Write-Host "Restore complete."