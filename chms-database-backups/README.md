# ChMS Database Backup & Migration

This directory contains the database backups and migration scripts for moving ChMS from the local-llama-wsl2-server to its own Docker environment.

## 📁 Files Created

### Backup Files (Timestamp: 20251009_204956)
- `chms_backup_20251009_204956.sql` - ChMS database only (46KB)
- `full_backup_20251009_204956.sql` - Complete PostgreSQL dump (329KB)
- `litellm_backup_20251009_204956.sql` - LiteLLM database only (281KB)
- `backup_info_20251009_204956.txt` - Detailed backup information

### Scripts
- `backup-from-server.sh` - Script to backup databases from server repo
- `restore-to-chms.sh` - Script to restore database to ChMS environment

## 🗄️ Database Information

### ChMS Database Tables (20 tables)
The ChMS database contains the following tables:
- `badge_types` - Badge type definitions
- `families` - Family records
- `members` - Member information
- `member_attributes` - Custom member attributes
- `member_badges` - Member badge assignments
- `member_notes` - Member notes and comments
- `organizations` - Organization settings
- `users` - User accounts
- `service_schedules` - Service scheduling
- And more...

### PostgreSQL Version
- **Version**: PostgreSQL 16.9 on x86_64-pc-linux-musl
- **Encoding**: UTF8
- **Locale**: en_US.utf8

## 🚀 Migration Process

### Phase 1: Backup Completed ✅
```bash
# Already completed - backups created and saved to ChMS repo
./backup-from-server.sh
```

### Phase 2: Set Up ChMS Environment
1. Create ChMS Docker Compose configuration
2. Set up PostgreSQL service for ChMS
3. Configure Cloudflare tunnel for ChMS
4. Set up Laravel Sail integration

### Phase 3: Restore Database
```bash
# In ChMS repository:
cd database-backups
./restore-to-chms.sh
```

### Phase 4: Verify Migration
1. Start ChMS services
2. Test database connectivity
3. Verify all data is present
4. Test application functionality

## 📋 Next Steps

1. **Review backup files** - Ensure all data is captured correctly
2. **Set up ChMS Docker environment** - Create docker-compose.yml for ChMS
3. **Configure new Cloudflare tunnel** - Set up chms.jerryagenyi.xyz
4. **Restore database** - Use restore-to-chms.sh script
5. **Test ChMS application** - Verify all functionality works

## 🔧 Architecture Decision

Based on the analysis, we're keeping PostgreSQL in both environments:

### Server Repo (local-llama-wsl2-server)
- **Keeps**: PostgreSQL for LiteLLM and AI tools
- **Services**: N8N, LiteLLM, Flowise, Agent Zero
- **Database**: LiteLLM configuration and data

### ChMS Repo (New Environment)
- **Gets**: New PostgreSQL instance for ChMS
- **Services**: Laravel, PostgreSQL, Cloudflare tunnel
- **Database**: ChMS application data

This approach provides:
- ✅ **Clean separation** between AI tools and ChMS
- ✅ **Independent scaling** and maintenance
- ✅ **No cross-dependencies** between systems
- ✅ **Simplified troubleshooting** and updates

## 📞 Support

If you encounter any issues during migration:
1. Check the backup_info file for detailed information
2. Verify Docker containers are running
3. Check database connectivity
4. Review application logs

The backup process captured all ChMS data successfully and is ready for migration! 🎉
