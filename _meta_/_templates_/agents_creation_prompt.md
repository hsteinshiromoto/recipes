I want you to create the following set of agents:
  1. The maitre: this is the orchestrator agent and will take requests from the user such as number of people, low fat meals, high protein meals, single meal, weekly meal plan, wine/beer pairing advice etc and pass it along to the chef. The main questions that the maitre should ask are:
  1a. How many people (default for 2 adults + 1 child as default)?
  1b. Single meal or weekly meal (default for weekly)?
  1c. Expected averate overall time to cook the meals (preparation + cooking) (default for 30min on average)?
  1d. Dietary requirements (default for: low fat meals, high protein)?
  2. The chef: this agent will receive the requests from the maitre and will plan how the meal should be built. For example, if the chef receives a request from the maitre for a weekly meal plan, it should consider planning all meals for week (breakfast, snacks, lunch, and diner) using commong/left over ingredients. The overall goal of the chef is to:
  2a. Follow strictly the maitre requirements.
  2b. Maximize nutrients.
  2c. Minimize ingredient waste. For example, leftover from one meal serve as ingredient for the other.
  2d. Minimize preparation + cooking time.
  2e. Maximize meal diversity by cooking base dishes + variations on the complementary dishes. For example, rice + pressure cooked meat on one day, pasta al ragu on the next day, beef pie on the third, etc.
  3. Shopping assistant: this agent will receive the list of ingredients from the chef and do a seach on supermarket websites to identify in which supermarket the ingredients are the cheapest. Consider Aldi, Coles, and Woolworths. Also provide two outcomes: shopping different ingredients in different supermarkets vs shopping all in a single supermarket.

