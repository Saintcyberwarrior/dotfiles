import os
import shutil
import re

lyrics_dir = os.path.expanduser("~/Documents/mirror/Pleasure/Songs/lyrics")
target_dir = os.path.expanduser("~/Documents/mirror/Pleasure/Songs/lyrics_flat")

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

print(f"Flattening and TAGGING lyrics from {lyrics_dir} to {target_dir}...")

for root, dirs, files in os.walk(lyrics_dir):
    if root == target_dir:
        continue
    for file in files:
        if file.endswith(".lrc"):
            artist = os.path.basename(root)
            raw_title = os.path.splitext(file)[0]
            
            # Clean up title for the tag
            clean_title = re.sub(r'\s*\(.*$', '', raw_title)
            clean_title = re.sub(r'\s*\[.*$', '', clean_title).strip()
            
            new_filename = f"{artist} - {raw_title}.lrc"
            src_path = os.path.join(root, file)
            dst_path = os.path.join(target_dir, new_filename)
            
            try:
                with open(src_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                # Prepend tags
                tagged_content = f"[ar:{artist}]\n[ti:{clean_title}]\n{content}"
                
                with open(dst_path, 'w', encoding='utf-8') as f:
                    f.write(tagged_content)
                
                print(f"Processed: {new_filename}")
            except Exception as e:
                print(f"Error processing {file}: {e}")

print("Done! Lyrics are now tagged and flattened.")
