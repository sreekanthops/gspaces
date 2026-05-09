// Workspace Management JavaScript
// Handles user workspace interactions, uploads, and auto-save

let autoSaveEnabled = true;
let isDirty = false;
let selectedItem = null;

// Initialize workspace when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('Initializing workspace handlers...');
    // Wait for AnimatedBanner to be initialized
    setTimeout(() => {
        setupUploadHandlers();
        setupAutoSave();
        setupDeselectHandler();
    }, 100);
});

// Setup file upload handlers
function setupUploadHandlers() {
    const uploadZone = document.getElementById('uploadZone');
    const fileInput = document.getElementById('fileInput');
    const uploadButton = document.getElementById('uploadButton');
    
    if (!uploadZone || !fileInput || !uploadButton) return;
    
    // Button click to upload
    uploadButton.addEventListener('click', function(e) {
        e.stopPropagation();
        fileInput.click();
    });
    
    // File selection
    fileInput.addEventListener('change', function(e) {
        if (e.target.files && e.target.files.length > 0) {
            handleFiles(e.target.files);
            // Clear the input so the same file can be uploaded again
            e.target.value = '';
        }
    });
    
    // Drag and drop
    uploadZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.add('dragover');
    });
    
    uploadZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.remove('dragover');
    });
    
    uploadZone.addEventListener('drop', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        handleFiles(files);
    });
}

// Handle uploaded files
async function handleFiles(files) {
    if (!files || files.length === 0) return;
    
    console.log('Processing', files.length, 'files...');
    
    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        // Validate file type
        if (!file.type.startsWith('image/png')) {
            showNotification('Only PNG files are supported', 'error');
            continue;
        }
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            showNotification('File too large. Max size is 5MB', 'error');
            continue;
        }
        
        try {
            await uploadFile(file);
        } catch (error) {
            console.error('Upload error:', error);
            showNotification('Failed to upload ' + file.name, 'error');
        }
    }
}

// Upload single file to server
async function uploadFile(file) {
    console.log('Starting upload for file:', file.name);
    
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        
        reader.onload = async function(e) {
            const base64Data = e.target.result;
            console.log('File read complete, data length:', base64Data.length);
            
            try {
                console.log('Sending upload request to /api/workspace/upload');
                const response = await fetch('/api/workspace/upload', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        image_data: base64Data,
                        filename: file.name
                    })
                });
                
                console.log('Response status:', response.status);
                const result = await response.json();
                console.log('Response data:', result);
                
                if (result.success) {
                    console.log('Upload successful, adding item to banner');
                    // Add item to banner
                    addItemToBanner(result.item);
                    
                    // Update stats
                    uploadedToday++;
                    updateStats();
                    
                    showNotification('Item added successfully', 'success');
                    resolve(result);
                } else {
                    console.error('Upload failed:', result.message);
                    showNotification(result.message || 'Upload failed', 'error');
                    reject(new Error(result.message));
                }
            } catch (error) {
                console.error('Upload request failed:', error);
                showNotification('Failed to upload ' + file.name, 'error');
                reject(error);
            }
        };
        
        reader.onerror = function() {
            console.error('Failed to read file');
            reject(new Error('Failed to read file'));
        };
        
        reader.readAsDataURL(file);
    });
}

// Add new item to the banner
function addItemToBanner(item) {
    if (!window.animatedBannerInstance) {
        console.error('AnimatedBanner not initialized');
        return;
    }
    
    console.log('Adding item to banner:', item);
    
    // Use the existing addNewItem method from AnimatedBanner class (same as test page)
    window.animatedBannerInstance.addNewItem(item);
    console.log('Item added successfully using addNewItem:', item.id);
    
    // Update item count
    document.getElementById('itemCount').textContent = window.furnitureData.length;
}

// Handle item position/rotation changes
function handleItemChange(event) {
    isDirty = true;
    
    if (autoSaveEnabled) {
        // Debounce auto-save
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(() => {
            saveWorkspace(true);
        }, 2000); // Save 2 seconds after last change
    }
}

// Setup auto-save functionality
function setupAutoSave() {
    // Save before page unload if there are unsaved changes
    window.addEventListener('beforeunload', function(e) {
        if (isDirty) {
            e.preventDefault();
            e.returnValue = '';
            saveWorkspace(false);
        }
    });
}

// Save workspace state
async function saveWorkspace(isAutoSave = false) {
    if (!banner) return;
    
    const indicator = document.getElementById('saveIndicator');
    const saveText = document.getElementById('saveText');
    
    // Show saving indicator
    if (indicator && saveText) {
        indicator.className = 'save-indicator saving';
        saveText.textContent = 'Saving...';
    }
    
    try {
        // Collect all item states
        const items = [];
        const elements = banner.container.querySelectorAll('.furniture-item');
        
        elements.forEach(element => {
            const itemId = element.dataset.itemId;
            const transform = element.style.transform;
            
            // Parse transform values
            let x = 0, y = 0, rotation = 0, scale = 1;
            
            const translateMatch = transform.match(/translate\(([^,]+),\s*([^)]+)\)/);
            if (translateMatch) {
                x = parseFloat(translateMatch[1]);
                y = parseFloat(translateMatch[2]);
            }
            
            const rotateMatch = transform.match(/rotate\(([^)]+)deg\)/);
            if (rotateMatch) {
                rotation = parseFloat(rotateMatch[1]);
            }
            
            const scaleMatch = transform.match(/scale\(([^)]+)\)/);
            if (scaleMatch) {
                scale = parseFloat(scaleMatch[1]);
            }
            
            items.push({
                id: itemId,
                position_x: x,
                position_y: y,
                rotation_angle: rotation,
                scale_factor: scale,
                z_index: parseInt(element.style.zIndex || 1)
            });
        });
        
        // Send to server
        const response = await fetch('/api/workspace/save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ items })
        });
        
        const result = await response.json();
        
        if (result.success) {
            isDirty = false;
            
            // Show success indicator
            if (indicator && saveText) {
                indicator.className = 'save-indicator saved';
                saveText.textContent = isAutoSave ? 'Auto-saved' : 'Saved';
                
                setTimeout(() => {
                    indicator.style.display = 'none';
                }, 2000);
            }
            
            if (!isAutoSave) {
                showNotification('Workspace saved successfully', 'success');
            }
        } else {
            throw new Error(result.message || 'Save failed');
        }
    } catch (error) {
        console.error('Save error:', error);
        
        if (indicator && saveText) {
            indicator.className = 'save-indicator';
            indicator.style.display = 'none';
        }
        
        if (!isAutoSave) {
            showNotification('Failed to save workspace', 'error');
        }
    }
}

// Clear all items from workspace
async function clearWorkspace() {
    if (!confirm('Are you sure you want to clear all items? This cannot be undone.')) {
        return;
    }
    
    try {
        const response = await fetch('/api/workspace/clear', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Clear banner using AnimatedBanner instance
            if (window.animatedBannerInstance) {
                window.animatedBannerInstance.container.innerHTML = '';
                window.animatedBannerInstance.items = [];
                window.animatedBannerInstance.furnitureElements = [];
            }
            
            // Clear data
            window.furnitureData = [];
            
            // Update stats
            updateStats();
            
            showNotification('Workspace cleared', 'success');
            
            // Reload page to reinitialize
            setTimeout(() => {
                location.reload();
            }, 1000);
        } else {
            throw new Error(result.message || 'Clear failed');
        }
    } catch (error) {
        console.error('Clear error:', error);
        showNotification('Failed to clear workspace', 'error');
    }
}

// Update statistics display
function updateStats() {
    const itemCount = document.getElementById('itemCount');
    const uploadCount = document.getElementById('uploadCount');
    
    if (itemCount && banner) {
        itemCount.textContent = banner.items.length;
    }
    
    if (uploadCount) {
        uploadCount.textContent = uploadedToday;
    }
}

// Show notification to user
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `alert alert-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'info'} alert-dismissible fade show`;
    notification.style.position = 'fixed';
    notification.style.top = '80px';
    notification.style.right = '20px';
    notification.style.zIndex = '9999';
    notification.style.minWidth = '300px';
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

// Handle item selection
function handleItemClick(element) {
    // Remove previous selection
    if (selectedItem) {
        selectedItem.style.outline = 'none';
        selectedItem.style.boxShadow = '';
    }
    
    // Select new item
    selectedItem = element;
    selectedItem.style.outline = '3px solid #667eea';
    selectedItem.style.boxShadow = '0 0 20px rgba(102, 126, 234, 0.5)';
    
    // Show delete button
    const deleteBtn = document.getElementById('deleteSelectedBtn');
    if (deleteBtn) {
        deleteBtn.style.display = 'block';
    }
}

// Delete selected item
async function deleteSelected() {
    if (!selectedItem) {
        showNotification('No item selected', 'error');
        return;
    }
    
    const itemId = selectedItem.dataset.itemId;
    
    if (!confirm('Are you sure you want to delete this item?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/workspace/item/${itemId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Remove from DOM
            selectedItem.remove();
            selectedItem = null;
            
            // Hide delete button
            const deleteBtn = document.getElementById('deleteSelectedBtn');
            if (deleteBtn) {
                deleteBtn.style.display = 'none';
            }
            
            // Update stats
            updateStats();
            
            showNotification('Item deleted successfully', 'success');
        } else {
            throw new Error(result.message || 'Delete failed');
        }
    } catch (error) {
        console.error('Delete error:', error);
        showNotification('Failed to delete item', 'error');
    }
}

// Deselect item when clicking outside
function setupDeselectHandler() {
    const container = document.getElementById('animated-furniture-banner');
    if (container) {
        container.addEventListener('click', function(e) {
            // If clicking on the container itself (not an item)
            if (e.target === container) {
                if (selectedItem) {
                    selectedItem.style.outline = 'none';
                    selectedItem.style.boxShadow = '';
                    selectedItem = null;
                    
                    const deleteBtn = document.getElementById('deleteSelectedBtn');
                    if (deleteBtn) {
                        deleteBtn.style.display = 'none';
                    }
                }
            }
        });
    }
}

// Handle item selection
function handleItemClick(element) {
    // Remove previous selection
    if (selectedItem) {
        selectedItem.style.outline = 'none';
        selectedItem.style.boxShadow = '';
    }
    
    // Select new item
    selectedItem = element;
    selectedItem.style.outline = '3px solid #667eea';
    selectedItem.style.boxShadow = '0 0 20px rgba(102, 126, 234, 0.5)';
    
    // Show control panel
    const controlPanel = document.getElementById('itemControlPanel');
    if (controlPanel) {
        controlPanel.style.display = 'block';
    }
}

// Close control panel
function closeControlPanel() {
    const controlPanel = document.getElementById('itemControlPanel');
    if (controlPanel) {
        controlPanel.style.display = 'none';
    }
    
    if (selectedItem) {
        selectedItem.style.outline = 'none';
        selectedItem.style.boxShadow = '';
        selectedItem = null;
    }
}

// Rotate item
function rotateItem(degrees) {
    if (!selectedItem) return;
    
    const transform = selectedItem.style.transform;
    const match = transform.match(/rotate\(([^)]+)deg\)/);
    const currentRotation = match ? parseFloat(match[1]) : 0;
    const newRotation = currentRotation + degrees;
    
    // Update transform
    const translateMatch = transform.match(/translate\(([^,]+),\s*([^)]+)\)/);
    const scaleMatch = transform.match(/scale\(([^)]+)\)/);
    
    const x = translateMatch ? translateMatch[1] : '0px';
    const y = translateMatch ? translateMatch[2] : '0px';
    const scale = scaleMatch ? scaleMatch[1] : '1';
    
    selectedItem.style.transform = `translate(${x}, ${y}) rotate(${newRotation}deg) scale(${scale})`;
    handleItemChange();
}

// Scale item
function scaleItem(delta) {
    if (!selectedItem) return;
    
    const transform = selectedItem.style.transform;
    const scaleMatch = transform.match(/scale\(([^)]+)\)/);
    const currentScale = scaleMatch ? parseFloat(scaleMatch[1]) : 1;
    const newScale = Math.max(0.1, Math.min(3, currentScale + delta));
    
    // Update transform
    const translateMatch = transform.match(/translate\(([^,]+),\s*([^)]+)\)/);
    const rotateMatch = transform.match(/rotate\(([^)]+)deg\)/);
    
    const x = translateMatch ? translateMatch[1] : '0px';
    const y = translateMatch ? translateMatch[2] : '0px';
    const rotation = rotateMatch ? rotateMatch[1] : '0';
    
    selectedItem.style.transform = `translate(${x}, ${y}) rotate(${rotation}deg) scale(${newScale})`;
    handleItemChange();
}

// Flip item
function flipItem(direction) {
    if (!selectedItem) return;
    
    const currentTransform = selectedItem.style.transform;
    
    if (direction === 'horizontal') {
        if (currentTransform.includes('scaleX(-1)')) {
            selectedItem.style.transform = currentTransform.replace('scaleX(-1)', 'scaleX(1)');
        } else {
            selectedItem.style.transform = currentTransform + ' scaleX(-1)';
        }
    } else if (direction === 'vertical') {
        if (currentTransform.includes('scaleY(-1)')) {
            selectedItem.style.transform = currentTransform.replace('scaleY(-1)', 'scaleY(1)');
        } else {
            selectedItem.style.transform = currentTransform + ' scaleY(-1)';
        }
    }
    
    handleItemChange();
}

// Export functions for global access
window.saveWorkspace = saveWorkspace;
window.clearWorkspace = clearWorkspace;
window.deleteSelected = deleteSelected;
window.closeControlPanel = closeControlPanel;
window.rotateItem = rotateItem;
window.scaleItem = scaleItem;
window.flipItem = flipItem;

// Made with Bob
