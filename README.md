<!-- At the very top of your .md file -->
<head>
<style>
body {
  text-align: justify
}
footer {
  display: block;
  width: 100%;
  margin-top: 20px;
  padding-top: 15px;
  border-top: 1px solid #ddd;
}
.custom-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background-color: white;
  font-size: 0.9em;
  text-align: center;
}
wimr  {
  display: block;
  height: 5px;
  background: linear-gradient(to right, #8B0000, #CC5500, #FFA500, #FFD700);
  margin: 20px 0;
  border: none;
}
/* Ensures each section (left, center, right) is evenly spaced */
.custom-footer div {
  flex: 1;
  padding: 5px;
}

/* Styling for the links inside the footer */
.custom-footer a {
  color: #007bff;
  text-decoration: none;
  font-weight: bold;
}

.custom-footer a:hover {
  text-decoration: underline;
}
.hint-goals {
  background-color: #FFE6FF; /* Light pink */
  border-left: 4px solid #FF40FF; /* Bright pink */
  padding: 10px 15px 0px;
  border-radius: 5px;
  line-height: 2;
  display: flex;
  margin: 10px 0;
}
.hint-goals::before {
  content: "🎯 ";
  font-size: 1.5em;
  margin-right: 15px;
  padding: 0px 0px 10px;
  align-items: center;
  line-height: 1;
  display: flex;
}
.hint-info {
  background-color: #e7f3fe;
  border-left: 4px solid #2196F3;
  padding: 10px 15px 0px;
  border-radius: 5px;
  line-height: 2;
  display: flex;
  margin: 10px 0;
}
.hint-info::before {
  content: "ℹ️ ";
  font-size: 1.5em;
  margin-right: 15px;
  padding: 0px 0px 10px;
  align-items: center;
  line-height: 1;
  display: flex;
}
.hint-success {
  background-color: #e8f5e9;
  border-left: 4px solid #4CAF50;
  padding: 10px 15px 0px;
  border-radius: 5px;
  line-height: 2;
  display: flex;
  margin: 10px 0;
}
.hint-success::before {
  content: "✔️ ";
  font-size: 1.5em;
  margin-right: 15px;
  padding: 0px 0px 10px;
  align-items: center;
  line-height: 1;
  display: flex;
}
</style>
</head>

# *SkillTrees*

**SkillTrees** is a free, self-guided learning portal that you can run locally or distribute among your own circles. It is designed to be flexible and content-agnostic, allowing anyone to plug in their own "Skill Trees" without reinventing the portal interface.

<div class="hint-goals">
**SkillTrees** offers a structured way for learners to see:
</div>

- **Local Branches**: Content the learner already has stored locally (with progress and marks). 
- **Available Branches**: Additional learning modules that can be downloaded on demand. 
- **Skill Trees**: Thematic groupings of related branches, showing overall progress and per-branch progress or download options.  

This separation helps learners track their own progress across multiple domains or “Skill Tree” of content.

<wimr>

## Advantages 

<div class="hint-success">
**Free**: It's free.  
</div>

<div class="hint-success">
**Locally Hosted**: You can run **SkillTrees** on your own machine or within your institution’s network. No third-party server is required, keeping data private. 
</div>

<div class="hint-success">
**Customisable Content**: **SkillTrees** separates the portal’s user interface from the actual learning content. By pointing the app to a different list, you can instantly swap in your own vignettes or modules. 
</div>

<div class="hint-success">
**Progress Tracking**: Each local branch can show a percentage “mark” (calculated from `.questions.csv`), a difficulty rating, and a short description. *Users can visually see how far they’ve progressed.* 
</div>

<div class="hint-success">
**Downloadable Content**: Any new or updated modules that appear in `available.csv` can be downloaded on demand via a simple button.   
</div>

<div class="hint-success">
**Thematic Organisation**: Group related modules into "Skill Trees" to provide learners with a meaningful structure for exploring multiple learning paths.  
</div>

<wimr>

## How it Works

<div class="hint-info">
**Local Folder Structure:**
</div>  
You maintain a folder (e.g. `./SkillTrees/`) that contains subfolders, each with a `.ref.csv` describing the roadmap’s name, rating, key, and optionally a `.questions.csv` for computing marks.

The Shiny app scans these subfolders to build “My Branches,” automatically grouping any 100% modules as “Completed.”

<div class="hint-info">
**Available CSV**
</div>

A CSV file (e.g. `.available.csv`) lists additional modules with columns like key, branch, rating, download link, and foldername for storing them locally. This file can live in your repository or be served from GitHub.

If a user doesn’t already have a module locally (no matching key found in their subfolders), the app displays it under “Available Branches,” letting them download and unzip the module on demand.

<div class="hint-info">
**Trees CSV**:
</div>

Another file (e.g. `.trees.csv`) can define “Skill Trees” by listing name and a combined key string of multiple subkeys (e.g., gen1_gen2_sc1). The app parses these subkeys, checks whether the user already has them locally or if they appear in the available CSV, and displays the user’s progress or a download button accordingly.

<div class="hint-info">
**Progress Calculation**:
</div>

Each local roadmap can have a `.questions.csv` used to compute an overall “mark” based on fraction correct. In-progress modules display partial percentages; completed modules appear at 100%.

<wimr>

## Reuse & Repurposing

<div class="hint-success">
**SkillTrees** is content-agnostic. You can:
</div>

**Swap Out available.csv**: If you have a custom set of modules or vignettes for a different subject or department, simply host your own available.csv (and trees.csv) that references those modules.

**Maintain Group-Specific Branches**: Learners can store local modules (each in a subfolder with a `.ref.csv`) for group-specific content.

**Host or Distribute**: You can provide the portal as a local zip or GitHub repository. Colleagues can run the Shiny app, scan their own local subfolders, and optionally pull your `available.csv` if they want to see your curated vignettes.

<wimr>

# Getting Started

1. Create a `/SkillTrees` folder that you will use for this app. 
2. Either download the dashboard.R directly from GitHub, or move to that directory and type:  
`download.file(url("https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/dashboard.R"), "dashboard.R", method="auto")` 
3.  Run the app using runDashboard(). Adjust the `available` and `trees` links as needed. The default is set to the default Intro to R link.

If you're a developer wanting the templates for developing your own **SkillTrees**, please reach out to me (thomas.oneil@sydney.edu.au) for the starter kit. 

<wimr>

<div class='custom-footer'>
<div class='footer-centre'>
<a href='https://paypal.me/drthomasoneil?country.x=AU&locale.x=en_AU' target='_blank'>
<strong>Support the Creator of<br>
<span style='font-size:2em'>SkillTree</span></strong>
</a>
</div>
</div>
<hr><br>




