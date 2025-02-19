# SkillTrees

SkillTrees is a free, self-guided learning portal that you can run locally or distribute among your own circles. It is designed to be flexible and content-agnostic, allowing anyone to plug in their own "Skill Trees" without reinventing the portal interface.

**SkillTrees** offers a structured way for learners to see:

- **Local Branches**: Content the learner already has stored locally (with progress and marks). 
- **Available Branches**: Additional learning modules that can be downloaded on demand. 
- **Skill Trees**: Thematic groupings of related branches, showing overall progress and per-branch progress or download options.  

This separation helps learners track their own progress across multiple domains or “Skill Tree” of content.

## Advantages 

- **Free**: It's free.  
- **Locally Hosted**: You can run SkillTrees on your own machine or within your institution’s network. No third-party server is required, keeping data private. 
- **Customisable Content**: SkillTrees separates the portal’s user interface from the actual learning content. By pointing the app to a different list, you can instantly swap in your own vignettes or modules. 
- **Progress Tracking**: Each local branch can show a percentage “mark” (calculated from `.questions.csv`), a difficulty rating, and a short description. *Users can visually see how far they’ve progressed.* 
- **Downloadable Content**: Any new or updated modules that appear in `available.csv` can be downloaded on demand via a simple button.   
- **Thematic Organisation**: Group related modules in “SkillTrees” to provide learners with a meaningful structure for exploring multiple learning paths.  

## How it Works

**Local Folder Structure:**

You maintain a folder (e.g. `./SkillTrees/`) that contains subfolders, each with a `.ref.csv` describing the roadmap’s name, rating, key, and optionally a `.questions.csv` for computing marks.

The Shiny app scans these subfolders to build “My Branches,” automatically grouping any 100% modules as “Completed.”

**Available CSV**

A CSV file (e.g. `.available.csv`) lists additional modules with columns like key, branch, rating, download link, and foldername for storing them locally. This file can live in your repository or be served from GitHub.

If a user doesn’t already have a module locally (no matching key found in their subfolders), the app displays it under “Available Branches,” letting them download and unzip the module on demand.

**Trees CSV**:

Another file (e.g. `.trees.csv`) can define “SkillTrees” by listing name and a combined key string of multiple subkeys (e.g., gen1_gen2_sc1). The app parses these subkeys, checks whether the user already has them locally or if they appear in the available CSV, and displays the user’s progress or a download button accordingly.

**Progress Calculation**:

Each local roadmap can have a `.questions.csv` used to compute an overall “mark” based on fraction correct. In-progress modules display partial percentages; completed modules appear at 100%.

## Reuse & Repurposing

SkillTrees is content-agnostic. You can:

**Swap Out available.csv**: If you have a custom set of modules or vignettes for a different subject or department, simply host your own available.csv (and trees.csv) that references those modules.

**Maintain Group-Specific Branches**: Learners can store local modules (each in a subfolder with a `.ref.csv`) for group-specific content.

**Host or Distribute**: You can provide the portal as a local zip or GitHub repository. Colleagues can run the Shiny app, scan their own local subfolders, and optionally pull your `available.csv` if they want to see your curated vignettes.

## Creating new content:

### Creating a new Branch

Each Branch is a self-contained learning module (or “roadmap”) located in a dedicated folder. Inside this folder, you must have:

- **.ref.csv** — Describes the Branch’s metadata (name, creator, difficulty rating, theme, short description, and a set of “nodes”).  
- **.questions.csv (optional)** — Contains question-answer pairs for computing user “marks” or progress in this Branch.

#### .ref.csv 

branch | creator | charity | key | rating | theme | descript | Node1 | Node*N* |
--- |--- |--- |--- |--- |--- |--- |--- |--- | 
Getting Started in Data Analysis | [yourname] | [donation] |[key] |[1-5] |[theme] |[description] | [NodeKey] | [NodeKey...] |
| | [yourlinks] | [donationlink] |  | | | | 1| | 
| | | | | | | | [date] | [date] |

- **branch**: A descriptive title for your Branch or learning module (e.g., “Getting Started in Data Analysis”). 
- **creator**: Your name or handle, so users know who authored the content. Optionally, you can link personal pages or other references.  
- **charity**: A placeholder that can direct users to a donation or philanthropic cause. Could be your institute or a research group link. 
- **key**: The most critical field - a unique string that aligns with the rest of the SkillTrees dashboard. This key must match the references in `available.csv` and any other places referencing this Branch. 
- **rating**: A difficulty rating (1 to 5). The dashboard uses this value to show star icons, helping users see how challenging the Branch might be.   
- **theme**: A top-level category (e.g., “Finance,” “Imaging,” “HR,” or “Data Science”).  
- **descript**: A short description of the Branch content. This may appear in the UI under “My Branches” or other sections.  
- **nodes**: Each column from Node1 through NodeN represents a discrete sub-topic or “vignette” within this Branch.  
  - *Row 1*: The “title” or “key” of that node. 
  - *Row 2*: Holds 1 when the user has completed that node, or 0/NA if not. 
  - *Row 3*: A date stamp or other info (e.g., date/time of completion).  

<details><summary>**Creator and Charity**</summary>

Given the open-source nature of this content distribution, we added these fields so creators could potentially receive compensation via donations, and designate a charity or institute as a donation beneficiary. This remains optional for each Branch and will be called using the `footer()` function.

</details>

<hr>

#### .questions.csv 

If you want to incorporate question-answer logic (like multiple choice quizzes), create a `.questions.csv` in the same folder. The app can read these to compute a “mark” (percent correct) for each Branch. Typically, `.questions.csv` has columns like:

**questions**

Displays the question using html format.  
E.g. for multiple choice questions.
What is the Capity City of Australia?<br> A) Sydney<br> B) Melbourne<br> C) Canberra<br> D) Adelaide<br>  
E.g. for coding related questions: Set your directory:

**correct** 
Stores the correct answer, For mcq, this would be A-D. For coding related questions, it can be an expected input string ("answer") OR an expected 
submitted response (getwd())

**result**  
Should remain empty and will store the users responses. 

**node**  
This will be a key that lets the functions used in a vignette know which question to display and which row to store answers. 
E.g. if 'Node1', you would use 'Node1' as an argument in the Vignette. 

**type**  
This needs to be either `mcq` for quiz-style questions, or something identifiable for individual questions, like `Question 1`. 

### Publishing the Branch

1. Once all of the Nodes have been created and the `.ref.csv` and `.questions.csv` files finalised, duplicate the incomplete Branch and check that it can be completed to 100% (*if you don't duplicate and test the questions, the .questions.csv will fill up with values!*).  
2. Zip the folder 
3. Adjust the `available.csv` file. (**IMPORTANT**: the key here should match the Branch key in `.ref.csv`!). These items are used as information for branches in the dashboard. 
4. If you're using GitHub for distribution, push the zip to your public GitHub site and paste the download link to the *download* column (e.g. might look like *https://github.com/DrThomasOneil/CVR-site/raw/refs/heads/master/docs/assets/python.zip*)  
5. If applicable, adjust the `trees.csv`. The key can be appended to an existing tree. Trees in the dashboard are ordered based on progress, but the Branches within the tree are based on the order they appear in this document. 


