# Quick Fix for Deployment Issue

## ❌ Current Error
```
Error: column "has_desk_mat" of relation "lead_designs" does not exist
```

## 🔍 Root Cause
The database migration (`add_item_quantities.sql`) hasn't been run yet on the server.

---

## ✅ Solution: Run These Commands on Server

### Step 1: SSH to Server
```bash
ssh ec2-user@13.127.245.37
cd /home/ec2-user/gspaces
```

### Step 2: Pull Latest Code
```bash
git pull origin leads
```

### Step 3: Backup Database (IMPORTANT!)
```bash
pg_dump -U sri gspaces > backup_before_quantity_$(date +%Y%m%d_%H%M%S).sql
```

### Step 4: Run Database Migration
```bash
psql -U sri -d gspaces -f add_item_quantities.sql
```

**Expected Output:**
```
ALTER TABLE
ALTER TABLE
ALTER TABLE
... (multiple ALTER TABLE statements)
```

### Step 5: Verify Columns Were Added
```bash
psql -U sri -d gspaces -c "\d lead_designs" | grep desk_mat
```

**Expected Output:**
```
 has_desk_mat        | boolean                  |           | default false
 desk_mat_quantity   | integer                  |           | default 1
 desk_mat_price      | numeric(10,2)            |           | default 0
 desk_mat_details    | text                     |           |
```

### Step 6: Restart Application
```bash
sudo systemctl restart python3
sudo systemctl status python3
```

### Step 7: Check Logs
```bash
sudo journalctl -u python3 -n 50
```

---

## 🧪 Test After Deployment

1. Open: `http://13.127.245.37/admin/leads`
2. Click "Create New Lead"
3. Add customer details
4. Click "Add Design Option"
5. Try checking "Desk Mat" checkbox
6. Enter quantity and price
7. Save - should work without errors!

---

## 🐛 If Migration Fails

### Check if columns already exist:
```bash
psql -U sri -d gspaces -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'lead_designs' AND column_name LIKE '%desk_mat%';"
```

### If columns exist but with wrong names:
```bash
# Rename columns if needed
psql -U sri -d gspaces -c "ALTER TABLE lead_designs RENAME COLUMN has_deskmat TO has_desk_mat;"
psql -U sri -d gspaces -c "ALTER TABLE lead_designs RENAME COLUMN deskmat_quantity TO desk_mat_quantity;"
psql -U sri -d gspaces -c "ALTER TABLE lead_designs RENAME COLUMN deskmat_price TO desk_mat_price;"
psql -U sri -d gspaces -c "ALTER TABLE lead_designs RENAME COLUMN deskmat_details TO desk_mat_details;"
```

---

## ✅ Success Indicators

After running all steps:
- ✅ No errors in application logs
- ✅ Can create new lead
- ✅ Can add items with quantities
- ✅ Calculations work in real-time
- ✅ Can save without errors
- ✅ Customer view shows quantity badges

---

## 📞 Quick Troubleshooting

### Error: "permission denied"
```bash
# Check file permissions
ls -la add_item_quantities.sql
# Should be readable by ec2-user
```

### Error: "database does not exist"
```bash
# List databases
psql -U sri -l
# Should show 'gspaces' database
```

### Error: "role does not exist"
```bash
# Check PostgreSQL users
psql -U postgres -c "\du"
# Should show 'sri' user
```

---

## 🎯 One-Line Deploy (Copy-Paste)

```bash
ssh ec2-user@13.127.245.37 "cd /home/ec2-user/gspaces && git pull origin leads && pg_dump -U sri gspaces > backup_\$(date +%Y%m%d_%H%M%S).sql && psql -U sri -d gspaces -f add_item_quantities.sql && sudo systemctl restart python3 && sudo systemctl status python3"
```

---

**The key issue:** You pulled the code but didn't run the database migration yet!
**Solution:** Run Step 4 above to add the missing columns.