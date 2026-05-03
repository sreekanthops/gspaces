-- Add missing columns to lead_designs table for all quantity-based items
-- This fixes the "column does not exist" error

ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS has_carpet BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS carpet_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS carpet_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS carpet_details TEXT,

ADD COLUMN IF NOT EXISTS has_curtains BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS curtains_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS curtains_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS curtains_details TEXT,

ADD COLUMN IF NOT EXISTS has_wall_art BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS wall_art_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS wall_art_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS wall_art_details TEXT,

ADD COLUMN IF NOT EXISTS has_desk_organizer BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS desk_organizer_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_organizer_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_organizer_details TEXT,

ADD COLUMN IF NOT EXISTS has_monitor_stand BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS monitor_stand_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monitor_stand_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS monitor_stand_details TEXT,

ADD COLUMN IF NOT EXISTS has_cable_management BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS cable_management_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS cable_management_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS cable_management_details TEXT,

ADD COLUMN IF NOT EXISTS has_desk_mat BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS desk_mat_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_mat_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_mat_details TEXT,

ADD COLUMN IF NOT EXISTS has_footrest BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS footrest_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS footrest_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS footrest_details TEXT,

ADD COLUMN IF NOT EXISTS has_keyboard BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS keyboard_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS keyboard_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS keyboard_details TEXT,

ADD COLUMN IF NOT EXISTS has_mouse BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS mouse_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS mouse_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS mouse_details TEXT,

ADD COLUMN IF NOT EXISTS has_monitor BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS monitor_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monitor_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS monitor_details TEXT,

ADD COLUMN IF NOT EXISTS has_laptop_stand BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS laptop_stand_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS laptop_stand_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS laptop_stand_details TEXT,

ADD COLUMN IF NOT EXISTS has_headphone_stand BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS headphone_stand_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS headphone_stand_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS headphone_stand_details TEXT,

ADD COLUMN IF NOT EXISTS has_whiteboard BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS whiteboard_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS whiteboard_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS whiteboard_details TEXT,

ADD COLUMN IF NOT EXISTS has_bookshelf BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS bookshelf_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS bookshelf_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS bookshelf_details TEXT,

ADD COLUMN IF NOT EXISTS has_trash_bin BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS trash_bin_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS trash_bin_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS trash_bin_details TEXT;

-- Verify the columns were added
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'lead_designs'
AND (column_name LIKE '%carpet%'
   OR column_name LIKE '%curtains%'
   OR column_name LIKE '%wall_art%'
   OR column_name LIKE '%desk_organizer%'
   OR column_name LIKE '%monitor_stand%'
   OR column_name LIKE '%cable_management%'
   OR column_name LIKE '%desk_mat%'
   OR column_name LIKE '%footrest%'
   OR column_name LIKE '%keyboard%'
   OR column_name LIKE '%mouse%'
   OR column_name LIKE '%monitor%'
   OR column_name LIKE '%laptop_stand%'
   OR column_name LIKE '%headphone_stand%'
   OR column_name LIKE '%whiteboard%'
   OR column_name LIKE '%bookshelf%'
   OR column_name LIKE '%trash_bin%')
ORDER BY column_name;

-- Made with Bob
