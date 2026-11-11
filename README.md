# ElvUI Loot Manager (ELM)

**ElvUI Loot Manager** is a lightweight ElvUI plugin that automates loot rolling, bypasses tedious confirmation popups, and handles complex Master Looter distributions instantly. 

---

* **✅ Popup Bypass**: Instantly confirms BoP binding alerts, loot rolls, and disenchant popups.
* **🎲 Auto-Roll Engine**:
  * **Need List**: Automatically roll **Need** on user-defined item IDs if possible.
  * **Greed Green/Blue Items**: Automatically roll **Greed** Green and Blue items based on your settings.
    * **Auto Disenchant**: Automatically roll **Disenchant** Green and Blue items (This option requires Greed Green/Blue items Active)
  * **Epic BoE Safeguard**: Automatically roll **Need** on Epic BoE items.
* **💰 Master Loot Auto-Distribution**: Automatically distributes items to assigned Players based on quality rules when you are the Master Looter:
> [!CAUTION] 
> Auto distribution will check for Player name if its misspelled, if player is offline or missing it will assign item to YOU (MASTER LOOTER). EXCEPT IN LEGENDARY CASE!
  * `Green & Blue` Items
  * `Epic Bind on Pickup` Items
  * `Epic Bind on Equip` Items
  * `Legendary` Items 
  > [!WARNING] 
  > `Legendary` option has built-in protection and requires exact Player name to distribute the item. In case the name is misspelled, player is offline or missing. Nothing happens and it requires manual distribution or NAME fixing within options.
* **🧹 Chat Cleanup**: Option to hide Blizzard loot messages while keeping you updated with neat, clean custom print actions.

---

## 🛠️ Commands & Configuration

Access the configuration panel directly in the **ElvUI settings menu** or use the chat command: `/ELM`

## 📦 How to Install

- Extract `ElvUI_LootManager-main.zip`
- Open Folder `ElvUI_LootManager-main`
- Copy Folder `ElvUI_LootManager`
- Paste Folder to: `Interface\AddOns`

> [!TIP]
> If You see a folder named `ElvUI_LootManager-main` inside your `AddOns` folder, **YOU DID IT WRONG** Take the folder out of it and put them in the main AddOns directory!

---
