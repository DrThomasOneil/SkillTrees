
# *SkillTrees*

**SkillTrees** is a free, self-guided learning portal that you can run locally or distribute among your own circles. It is designed to be flexible and content-agnostic, allowing anyone to plug in their own "Skill Trees" without reinventing the portal interface.

**SkillTrees** offers a structured way for learners to see:

- **Local Branches**: Content the learner already has stored locally (with progress and marks). 
- **Available Branches**: Additional learning modules that can be downloaded on demand. 
- **Skill Trees**: Thematic groupings of related branches, showing overall progress and per-branch progress or download options.  

This separation helps learners track their own progress across multiple domains or “Skill Tree” of content.

*For a full description see* [*the main site*](https://DrThomasOneil.github.io/SkillTrees)

<hr>

## Advantages 

**Free**: It's free.  

**Locally Hosted**: You can run **SkillTrees** on your own machine or within your institution’s network. No third-party server is required, keeping data private. 

**Customisable Content**: **SkillTrees** separates the portal’s user interface from the actual learning content. By pointing the app to a different list, you can instantly swap in your own vignettes or modules. 

**Progress Tracking**: Each local branch can show a percentage “mark” (calculated from `.questions.csv`), a difficulty rating, and a short description. *Users can visually see how far they’ve progressed.* 

**Downloadable Content**: Any new or updated modules that appear in `available.csv` can be downloaded on demand via a simple button.   

**Thematic Organisation**: Group related modules into "Skill Trees" to provide learners with a meaningful structure for exploring multiple learning paths.  

<hr>

## How it Works

**Local Folder Structure:**
You maintain a folder (e.g. `./SkillTrees/`) that contains subfolders, each with a `.ref.csv` describing the roadmap’s name, rating, key, and optionally a `.questions.csv` for computing marks.

The Shiny app scans these subfolders to build “My Branches,” automatically grouping any 100% modules as “Completed.”

**Available CSV**

A CSV file (e.g. `.available.csv`) lists additional modules with columns like key, branch, rating, download link, and foldername for storing them locally. This file can live in your repository or be served from GitHub.

If a user doesn’t already have a module locally (no matching key found in their subfolders), the app displays it under “Available Branches,” letting them download and unzip the module on demand.

**Trees CSV**:

Another file (e.g. `.trees.csv`) can define “Skill Trees” by listing name and a combined key string of multiple subkeys (e.g., gen1_gen2_sc1). The app parses these subkeys, checks whether the user already has them locally or if they appear in the available CSV, and displays the user’s progress or a download button accordingly.

**Progress Calculation**:

Each local roadmap can have a `.questions.csv` used to compute an overall “mark” based on fraction correct. In-progress modules display partial percentages; completed modules appear at 100%.

<hr>

## Reuse & Repurposing

**SkillTrees** is content-agnostic. You can:

**Swap Out available.csv**: If you have a custom set of modules or vignettes for a different subject or department, simply host your own available.csv (and trees.csv) that references those modules.

**Maintain Group-Specific Branches**: Learners can store local modules (each in a subfolder with a `.ref.csv`) for group-specific content.

**Host or Distribute**: You can provide the portal as a local zip or GitHub repository. Colleagues can run the Shiny app, scan their own local subfolders, and optionally pull your `available.csv` if they want to see your curated vignettes.

<hr>

# Getting Started

1. Create a `/SkillTrees` folder that you will use for this app. 
2. Either download the dashboard.R directly from GitHub, or move to that directory and type:  
`download.file(url("https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/dashboard.R"), "dashboard.R", method="auto")` 
3.  Run the app using runDashboard(). Adjust the `available` and `trees` links as needed. The default is set to the default Intro to R link.

If you're an educator or developer wanting the templates for developing your own **SkillTrees**, please reach out to me (thomas.oneil@sydney.edu.au) for the starter kit. 

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




