# ElvUI Loot Manager (ELM)

**ElvUI Loot Manager** is a lightweight ElvUI plugin that automates loot rolling, bypasses tedious confirmation popups, and handles complex Master Looter distributions instantly. 

---

## 🚀 Key Features

* **⚡ Popup Bypass**: Instantly confirms BoP binding alerts, loot rolls, and disenchant popups (`LOOT_BIND`, `CONFIRM_LOOT_ROLL`, `CONFIRM_DISENCHANT_ROLL`) with zero delay.
* **🎲 Auto-Roll Engine**:
  * **Need List**: Automatically rolls **Need** on user-defined item IDs.
  * **Epic BoE Safeguard**: Automatically rolls **Need** on Epic BoE items to ensure they aren't lost to greed[cite: 1].
  * **Greed & DE**: Automatically rolls **Greed** or **Disenchant** on Green and Blue items based on your settings[cite: 1].
* **👑 Master Loot Automation**: Automatically distributes items to assigned candidates based on quality rules when you are the Master Looter[cite: 1]:
  * `Green/Blue` Items[cite: 1]
  * `Epic BoP` Items[cite: 1]
  * `Epic BoE` Items[cite: 1]
  * `Legendary` Items[cite: 1]
* **🧹 Chat Cleanup**: Option to hide verbose Blizzard loot spam messages while keeping you updated with neat, clean custom print actions[cite: 1].
* **🎨 Custom UI & Aesthetics**: Built-in custom AceGUI widgets (`ELM_ScrollSelect`, `ELM_Input`, `ELM_Button`) with custom color gradients matching the class colors of raid targets[cite: 1].

---

## 🛠️ Commands & Configuration

Access the configuration panel directly in the **ElvUI settings menu** or use the chat command[cite: 1]:

```text
/elm
```

### 📦 How It Works (Technical Overview)

```text
                       [ Loot Event Captured ]
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
 [ Solo / Group Loot ]                             [ Master Loot Mode ]
   ├── Need List match? -> Auto Need                 ├── Item quality matches assignee?
   ├── Epic BoE? -> Auto Need                        │     ├── Candidate online? -> Auto-assign
   ├── Green/Blue? -> Auto Greed/DE                  │     └── Candidate offline? -> Fallback to Self
   └── Confirmation Popup? -> Auto Confirm           └── Legendary Target missing? -> Warn Chat
```

## 📝 To-Do List / Upcoming Features

* [ ] **Easy Item Linking**: Add the ability to paste or shift-click item links directly into configuration boxes for quicker Need List setup.
* [ ] **Performance & Speed Optimization**: Further refactor execution paths to ensure maximum speed and efficiency.
* [ ] **Combat Safeguard**: Optimize handling to ensure loot processing never interferes with or clutters the UI while the player is in combat.
