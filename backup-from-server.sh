#!/bin/bash

# ChMS Database Backup Script
# This script backs up the PostgreSQL databases from the local-llama-wsl2-server
# and saves them to the ChMS repository for migration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="chms-database-backups"
CHMS_BACKUP_DIR="C:/Users/Username/Documents/github/ChMS/database-backups"

# Database configuration (from your env.txt)
POSTGRES_USER="postgres"
POSTGRES_CONTAINER="postgres"

echo -e "${BLUE}🔄 Starting ChMS Database Backup Process${NC}"
echo -e "${BLUE}Timestamp: ${TIMESTAMP}${NC}"

# Create local backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Function to check if container is running
check_container() {
    if ! docker ps | grep -q "${POSTGRES_CONTAINER}"; then
        echo -e "${RED}❌ PostgreSQL container '${POSTGRES_CONTAINER}' is not running!${NC}"
        echo -e "${YELLOW}💡 Please start your services with: docker compose up -d${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
}

# Function to create database backups
create_backups() {
    echo -e "${BLUE}📦 Creating database backups...${NC}"
    
    # 1. Full database backup (all databases)
    echo -e "${YELLOW}📋 Creating full database backup...${NC}"
    docker exec "${POSTGRES_CONTAINER}" pg_dumpall -U "${POSTGRES_USER}" > "${BACKUP_DIR}/full_backup_${TIMESTAMP}.sql"
    
    # 2. ChMS-specific database backup
    echo -e "${YELLOW}🏥 Creating ChMS database backup...${NC}"
    docker exec "${POSTGRES_CONTAINER}" pg_dump -U "${POSTGRES_USER}" chms_db > "${BACKUP_DIR}/chms_backup_${TIMESTAMP}.sql"
    
    # 3. LiteLLM database backup (for reference)
    echo -e "${YELLOW}🤖 Creating LiteLLM database backup...${NC}"
    docker exec "${POSTGRES_CONTAINER}" pg_dump -U "${POSTGRES_USER}" postgres > "${BACKUP_DIR}/litellm_backup_${TIMESTAMP}.sql"
    
    echo -e "${GREEN}✅ Database backups created successfully${NC}"
}

# Function to create backup info file
create_backup_info() {
    echo -e "${BLUE}📝 Creating backup information file...${NC}"
    
    cat > "${BACKUP_DIR}/backup_info_${TIMESTAMP}.txt" << EOF
ChMS Database Backup Information
================================
Backup Date: $(date)
Timestamp: ${TIMESTAMP}
Source Server: local-llama-wsl2-server
PostgreSQL Version: $(docker exec ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -t -c "SELECT version();" | head -1 | xargs)

Backup Files:
- full_backup_${TIMESTAMP}.sql     : Complete PostgreSQL dump (all databases)
- chms_backup_${TIMESTAMP}.sql     : ChMS database only
- litellm_backup_${TIMESTAMP}.sql  : LiteLLM database only

Database Information:
$(docker exec ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -c "\l")

ChMS Database Tables:
$(docker exec ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d chms_db -c "\dt" 2>/dev/null || echo "ChMS database not found or empty")

Migration Notes:
- These backups are for migrating ChMS to its own Docker environment
- The ChMS database will be restored to a new PostgreSQL instance
- LiteLLM will remain in the original server setup
EOF
    
    echo -e "${GREEN}✅ Backup information file created${NC}"
}

# Function to copy backups to ChMS repository
copy_to_chms_repo() {
    echo -e "${BLUE}📂 Copying backups to ChMS repository...${NC}"
    
    # Create ChMS backup directory if it doesn't exist
    if [ ! -d "${CHMS_BACKUP_DIR}" ]; then
        echo -e "${YELLOW}📁 Creating ChMS backup directory: ${CHMS_BACKUP_DIR}${NC}"
        mkdir -p "${CHMS_BACKUP_DIR}"
    fi
    
    # Copy all backup files
    cp "${BACKUP_DIR}"/* "${CHMS_BACKUP_DIR}/"
    
    echo -e "${GREEN}✅ Backups copied to ChMS repository${NC}"
    echo -e "${BLUE}📍 Location: ${CHMS_BACKUP_DIR}${NC}"
}

# Function to display backup summary
display_summary() {
    echo -e "\n${GREEN}🎉 Backup Process Completed Successfully!${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${YELLOW}📊 Backup Summary:${NC}"
    
    echo -e "\n${BLUE}Local Backups ($(pwd)/${BACKUP_DIR}):${NC}"
    ls -la "${BACKUP_DIR}/"
    
    echo -e "\n${BLUE}ChMS Repository Backups (${CHMS_BACKUP_DIR}):${NC}"
    ls -la "${CHMS_BACKUP_DIR}/"
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo -e "1. Review backup files in: ${CHMS_BACKUP_DIR}"
    echo -e "2. Set up ChMS Docker environment"
    echo -e "3. Use restore-to-chms.sh to restore the database"
    echo -e "4. Test ChMS application with restored data"
    
    echo -e "\n${GREEN}✅ Ready for ChMS migration!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting backup process...${NC}\n"
    
    check_container
    create_backups
    create_backup_info
    copy_to_chms_repo
    display_summary
    
    echo -e "\n${GREEN}🏁 Backup script completed successfully!${NC}"
}

# Run main function
main "$@"
