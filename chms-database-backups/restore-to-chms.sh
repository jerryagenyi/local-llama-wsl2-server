#!/bin/bash

# ChMS Database Restore Script
# This script restores the PostgreSQL database backup to the ChMS Docker environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="."
POSTGRES_CONTAINER="chms-postgres"
POSTGRES_USER="postgres"
POSTGRES_DB="chms_db"

echo -e "${BLUE}🔄 Starting ChMS Database Restore Process${NC}"

# Function to find the latest backup files
find_latest_backup() {
    LATEST_TIMESTAMP=$(ls -1 chms_backup_*.sql 2>/dev/null | sed 's/chms_backup_\(.*\)\.sql/\1/' | sort -r | head -1)
    
    if [ -z "$LATEST_TIMESTAMP" ]; then
        echo -e "${RED}❌ No ChMS backup files found!${NC}"
        echo -e "${YELLOW}💡 Please ensure backup files are in the current directory${NC}"
        exit 1
    fi
    
    CHMS_BACKUP_FILE="chms_backup_${LATEST_TIMESTAMP}.sql"
    FULL_BACKUP_FILE="full_backup_${LATEST_TIMESTAMP}.sql"
    BACKUP_INFO_FILE="backup_info_${LATEST_TIMESTAMP}.txt"
    
    echo -e "${GREEN}✅ Found backup files with timestamp: ${LATEST_TIMESTAMP}${NC}"
    echo -e "${BLUE}📁 ChMS backup: ${CHMS_BACKUP_FILE}${NC}"
}

# Function to check if container is running
check_container() {
    if ! docker ps | grep -q "${POSTGRES_CONTAINER}"; then
        echo -e "${RED}❌ PostgreSQL container '${POSTGRES_CONTAINER}' is not running!${NC}"
        echo -e "${YELLOW}💡 Please start your ChMS services with: docker compose up -d${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
}

# Function to wait for database to be ready
wait_for_database() {
    echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
    
    for i in {1..30}; do
        if docker exec "${POSTGRES_CONTAINER}" pg_isready -U "${POSTGRES_USER}" -d postgres >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Database is ready${NC}"
            return 0
        fi
        echo -e "${YELLOW}⏳ Waiting for database... (${i}/30)${NC}"
        sleep 2
    done
    
    echo -e "${RED}❌ Database failed to become ready${NC}"
    exit 1
}

# Function to create database if it doesn't exist
create_database() {
    echo -e "${BLUE}🗄️ Creating ChMS database if it doesn't exist...${NC}"
    
    # Check if database exists
    DB_EXISTS=$(docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -lqt | cut -d \| -f 1 | grep -w "${POSTGRES_DB}" | wc -l)
    
    if [ "$DB_EXISTS" -eq 0 ]; then
        echo -e "${YELLOW}📝 Creating database: ${POSTGRES_DB}${NC}"
        docker exec "${POSTGRES_CONTAINER}" createdb -U "${POSTGRES_USER}" "${POSTGRES_DB}"
        echo -e "${GREEN}✅ Database created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ Database ${POSTGRES_DB} already exists${NC}"
        echo -e "${YELLOW}🔄 Dropping and recreating for clean restore...${NC}"
        docker exec "${POSTGRES_CONTAINER}" dropdb -U "${POSTGRES_USER}" "${POSTGRES_DB}" --if-exists
        docker exec "${POSTGRES_CONTAINER}" createdb -U "${POSTGRES_USER}" "${POSTGRES_DB}"
        echo -e "${GREEN}✅ Database recreated successfully${NC}"
    fi
}

# Function to restore database
restore_database() {
    echo -e "${BLUE}📦 Restoring ChMS database from backup...${NC}"
    
    # Copy backup file to container
    docker cp "${CHMS_BACKUP_FILE}" "${POSTGRES_CONTAINER}:/tmp/chms_backup.sql"
    
    # Restore database
    echo -e "${YELLOW}🔄 Restoring database content...${NC}"
    docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f /tmp/chms_backup.sql
    
    # Clean up temporary file
    docker exec "${POSTGRES_CONTAINER}" rm /tmp/chms_backup.sql
    
    echo -e "${GREEN}✅ Database restored successfully${NC}"
}

# Function to verify restore
verify_restore() {
    echo -e "${BLUE}🔍 Verifying database restore...${NC}"
    
    # Check table count
    TABLE_COUNT=$(docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
    
    echo -e "${BLUE}📊 Tables restored: ${TABLE_COUNT}${NC}"
    
    # List tables
    echo -e "${BLUE}📋 Available tables:${NC}"
    docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "\dt"
    
    # Check some key tables for data
    echo -e "\n${BLUE}📈 Data verification:${NC}"
    
    # Check members table
    MEMBER_COUNT=$(docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM members;" 2>/dev/null | xargs || echo "0")
    echo -e "${YELLOW}👥 Members: ${MEMBER_COUNT}${NC}"
    
    # Check organizations table
    ORG_COUNT=$(docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM organizations;" 2>/dev/null | xargs || echo "0")
    echo -e "${YELLOW}🏢 Organizations: ${ORG_COUNT}${NC}"
    
    # Check users table
    USER_COUNT=$(docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
    echo -e "${YELLOW}👤 Users: ${USER_COUNT}${NC}"
    
    echo -e "${GREEN}✅ Database verification completed${NC}"
}

# Function to display restore summary
display_summary() {
    echo -e "\n${GREEN}🎉 Database Restore Completed Successfully!${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    if [ -f "${BACKUP_INFO_FILE}" ]; then
        echo -e "${YELLOW}📋 Backup Information:${NC}"
        cat "${BACKUP_INFO_FILE}" | head -10
    fi
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo -e "1. Start your ChMS application: docker compose up -d"
    echo -e "2. Check application logs: docker compose logs -f laravel"
    echo -e "3. Access ChMS at: https://chms.jerryagenyi.xyz (after tunnel setup)"
    echo -e "4. Verify all data and functionality"
    
    echo -e "\n${GREEN}✅ ChMS database is ready!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting restore process...${NC}\n"
    
    find_latest_backup
    check_container
    wait_for_database
    create_database
    restore_database
    verify_restore
    display_summary
    
    echo -e "\n${GREEN}🏁 Restore script completed successfully!${NC}"
}

# Run main function
main "$@"
