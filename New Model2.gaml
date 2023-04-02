/**
* Name: NewModel2
* Based on the internal empty template. 
* Author: linus
* Tags: 
*/


model NewModel2


global {
    int numberOfGuests <- 10;
	int numberOfStores <- 2;
	int numberOfInfo <- 1;
	int numberOfSecurityGuards <- 1;
	
	
	init {
		create Guest number:numberOfGuests;
		create DrinkStore number:numberOfStores;
		create FoodStore number:numberOfStores;
		create DrinkNFoodStore number:numberOfStores;
		create Info number:numberOfInfo
		{
			location <- {50,50};
		}
		create SecurityGuard number:numberOfSecurityGuards;
		
		loop counter from: 1 to: numberOfGuests {
			Guest my_agent <- Guest[counter - 1];
			my_agent <- my_agent.setName(counter);
		}	
		
		loop counter from: 1 to: numberOfStores {
			DrinkStore my_agent <- DrinkStore[counter - 1];
			my_agent <- my_agent.setName(counter);
    	}
    	
		loop counter from: 1 to: numberOfStores {
			FoodStore my_agent <- FoodStore[counter - 1];
			my_agent <- my_agent.setName(counter);
    	}
    	
		loop counter from: 1 to: numberOfStores {
			DrinkNFoodStore my_agent <- DrinkNFoodStore[counter - 1];
			my_agent <- my_agent.setName(counter);
    	}
		
	}

}

species Guest skills:[moving] {
	bool isHungry <- false;
	bool isThirsty <- false;
	int hunger <- rnd(1,100); 
	int thirst <- rnd(1,100); 	
	Location target <- nil;
	list<Store> smallbrian <- [];
	bool badApple <- flip(0.3);
	string guestName <- "Undefined";
	
	rgb color <- #green;
	
	aspect default
	{		
		draw sphere(3) at: location color:color;
	}
	
	action setName(int num) {
		guestName <- "Person " + num;
	}
	
	reflex gettingHungry when: !isHungry {
		hunger <- hunger - 1;
		if (hunger < 10) {
			isHungry <- true;
			write guestName + " is hungry ";
		}	
	}
	
	reflex gettingThirsty when: !isThirsty {
		thirst <- thirst - 2;
		if (thirst < 10) {
			isThirsty <- true;
			write guestName + " is thirsty ";
		}	
	}
	
	reflex whereToGo when: (isThirsty or isHungry) and (target = nil) {
		bool remeber <- flip(0.5);
		if (length(smallbrian) > 0 and remeber) {
			loop i from: 0 to: length(smallbrian)-1 {
				Store store <- smallbrian[i];
				if ((isHungry and isThirsty) and (store.hasFood and store.hasDrinks)) {
					target <- store;
					color <- #darkgreen;
					break;
				} else if (isThirsty and store.hasDrinks) {
					target <- store;
					color <- #lightskyblue;
					break;
				} else if (isHungry and store.hasFood) {
					target <- store;
					color <- #skyblue;
					break;
				}	
			}	
		} else {
			target <- one_of(Info);
			color <- #black;
			write guestName + " will go to the Info center";
		}

	}
	
	reflex move
	{
		if (target != nil) {
			do goto target:target.location;
		}
		else {
			do wander;
		}
	}
	
	reflex whenAtInfo when: target != nil and location distance_to (target) < 2{
				ask Info at_distance 2 {
					Store store;
					if (myself.isHungry and myself.isThirsty) {
						store <- drinknfoodstore closest_to myself.location;
						myself.color <- #blue;
					} else if (myself.isHungry and myself.isThirsty = false) {
						store <- foodstore closest_to myself.location;
						myself.color <- #purple;
					} else {
						store <- drinkstore closest_to myself.location;
						myself.color <- #lightskyblue;
					}

					myself.target <- store;
					write myself.guestName + " has been told to go to " + myself.target.name;
				}
	}
    
	reflex whenAtStore when: target != nil and location distance_to (target) < 2{
		if (isHungry and isThirsty) {
			isHungry <- false;
			isThirsty <- false;
			hunger <- 100;
			thirst <- 100;
		} else if (isHungry and isThirsty = false) {
			isHungry <- false;
			hunger <- 100;
		} else {
			isThirsty <- false;
			thirst <- 100;
		}	
		
		write guestName + " has replenished at " + target.name;

			
		bool remeber <- flip(0.5);
		if (remeber) {
			if(length(smallbrian) < 3) {
				smallbrian <+ target;
			} else {
				remove item:smallbrian[0] from:smallbrian;
				smallbrian <+ target;
			}
			write target.name + " has been added to " +guestName+ " memory";
		}
		
		color <- #green;
		target <- nil;
	}

}

species Location {}

species Store parent: Location {
    bool hasFood <- false;
    bool hasDrinks <- false;
    
	string storeName <- "Undefined";
    	
	action setName(int num) {
		storeName <- "Drink Store " + num;
	}
}

species DrinkStore parent: Store { 
    bool hasFood <- false;
    bool hasDrinks <- true;
    
	string storeName <- "Undefined";
	
	action setName(int num) {
		storeName <- "Drink Store " + num;
	}
	
	aspect default {
		rgb agentColor <- rgb("lightskyblue");
		draw square(5) color: agentColor;
	}
}

species FoodStore parent: Store { 
    bool hasFood <- true;
    bool hasDrinks <- false;
    
	string storeName <- "Undefined";
	
	action setName(int num) {
		storeName <- "Food Store " + num;
	}
	
	aspect default {
		rgb agentColor <- rgb("purple");
		draw square(5) color: agentColor;
	}
}

species DrinkNFoodStore parent: Store { 
    bool hasFood <- true;
    bool hasDrinks <- true;
    
	string storeName <- "Undefined";
	
	action setName(int num) {
		storeName <- "Drink and Food Store " + num;
	}
	
	aspect default {
		rgb agentColor <- rgb("blue");
		draw square(5) color: agentColor;
	}
}


species Info parent: Location {
 	list<Store> foodstore <- (FoodStore at_distance 1000);
	list<Store> drinkstore <- (DrinkStore at_distance 1000);
	list<Store> drinknfoodstore <- (DrinkNFoodStore at_distance 1000);

	aspect default
	{
		draw hexagon(5) at: location color: #black;
	}
	
	reflex whenGuestVisit when: Guest at_distance (2) {
		Guest badapple <- nil;
		string gname <- nil;
		
		ask Guest at location {
			if (self.badApple) {
				gname <- self.guestName;
				badapple <- self;
			}
		}
		
		if (badapple != nil) {
			ask one_of(SecurityGuard) {
				if (!(badapples contains badapple)) {
					write "security called for "+ gname;
					badapples <+ badapple;
				}
				
			}
		}
	}
	
	
}

species SecurityGuard skills:[moving] {
	list<Guest> badapples <- [];
	Guest target <- nil;
	float killSpeed <- 2.5;
	
	reflex chooseTarget when: length(badapples) > 0 and target = nil {
		target <- badapples[0];
	}
	
	reflex move
	{
		if (target != nil) {
			do goto target:target.location  speed:killSpeed;
		}
		else {
			do wander;
		}
	}
	
 	reflex killTheGuest when: target != nil and location distance_to (target) < 2 {
		write "kill" + target.guestName;
		ask target {
			do die;
		}
		target <- nil;
		remove item:badapples[0] from:badapples;
	}
	 
	
		aspect default
	{
		draw circle(2) at: location color: #red;
	}
}

experiment my_experiment type:gui
{
    output {
		display map type: opengl
		{
			species Guest;
			species DrinkStore;
			species FoodStore;
			species DrinkNFoodStore;
			species Info;
			species SecurityGuard;
		}
    }
}