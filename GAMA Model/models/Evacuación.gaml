/**
* Name: TurismModel
* Based on the internal empty template. 
* Author: arnau
* Tags: 
*/


model Evacuation

global {
	file shape_file_roads <- file("../includes/EJES-CALLE.shp"); /*document from which we obtain the street axis */
	file shape_file_buildings <- file("../includes/buildings2.shp"); /*document from which we obtain the buildings and qualiffications */
	geometry shape <- envelope(envelope(shape_file_buildings) + envelope(shape_file_roads));
	float step <- 10 #mn; /*How many time passes between stages in the model*/
	date starting_date <- date("2022-01-01-00-00-00"); /*Starting date */
	date evacuation_start <- date("2022-01-02-13-51-46"); /*Date in which the evacuation will start */
	int nb_locals_init <- 200; /*800.100 */ /*Number of locals initiated */
	int nb_turists_init <- 200; /*16.600 */ /*Number of turists initiated */
	float pr_drivers <- 0.3; /*Probability of a person to use its car*/
	int min_work_start <- 6; /*Minimal work start time */
	int max_work_start <- 10; /*Maximal work start time */
	int min_work_end <- 16;  /*Minimal work end time*/
	int max_work_end <- 20; /*Maximal work end time*/
	float min_speed_walk <- 3.76 #km / #h; /*Minimal speed walking*/
	float max_speed_walk <- 5.76 #km / #h; /*Maximal speed walking*/
	float max_speed_drive <- 50.0 #km / #h; /*Maximal speed driving*/
	float min_speed_drive <- 30.0 #km / #h; /*Minimal speed driving */
	graph the_graph;
	int nb_locals -> {length(locals)};
	int nb_turists -> {length(turist)};
	
	list<point> extraction <- [{9448.994329944253, 8960.12102743378, 0.0}, {2430.602399586991, 13486.818056559563, 0.0}, {6653.047153047097, 15553.562739025336, 0.0}, {2490.2340548641514, 2490.2340548641514, 0.0}, {3736.480656620377, 3736.480656620377, 0.0}, {4187.949939459097, 7665.710743002283, 0.0}, {14308.890108270862, 14308.890108270862, 0.0}];

reflex every_step{
	write current_date;
	}
	
reflex end_model when: nb_locals + nb_turists = 0{
	do pause;
}
	
	/*Process in which we initialize the agents*/
	init {
		/*We generate the random seed, that allows us to replicate this exact model*/
		seed <- 10;
		/*We create the building agents from the shape file and we recover the variables we will use */
		create building from: shape_file_buildings with: [type::string(read ("uso")), Trabajo::int(read("Trabajo")), Ocio::int(read("Ocio")), Residencial::int(read("Resdncl")), Turismo::int(read("Turismo")), Host::int(read("Host"))] {
			/*We distinguish between buildings using colors and their qualiffication */
			if type="Trabajo" {
				color <- #blue ;
			}
			if type = "Ocio"{
				color <- #green;
			}
			if type = "Turismo"{
				color <- #purple;
			}
			if type = "Area Terciaria y Residencial" or type = "Terciario"{
				color <- #orange;
			}
		}
		/*We create the street agents using the shape file*/
		create road from: shape_file_roads ;
		 /*Graph with the streets as edges*/
		the_graph <- as_edge_graph(road) with_weights(road as_map(each::geometry(each).perimeter));
		
		/*We generate four lists with the different kind of buildings */
		list<building> residential_buildings <- building where (each.Residencial=1);
		list<building> industrial_buildings <- building  where (each.Trabajo=1) ;
		list<building> recreative_buildings <- building where (each.Ocio=1);
		list<building> turism_buildings <- building where (each.Turismo = 1);
		list<building> host_buildings <- building where (each.Host = 1);
		/*We create a certain number of locals (defined previously) */
		create locals number: nb_locals_init {
			/*We generate their speed as a random number between the minimum and the maximum. We will assume they will start walking */
			speed <- rnd(min_speed_walk, max_speed_walk);
			/*We  generate their work start time as a random number between the minimum and the maximum*/
			start_work <- rnd (min_work_start, max_work_start);
			/*We  generate their work end time as a random number between the minimum and the maximum*/
			end_work <- rnd(min_work_end, max_work_end);
			/*We assign their home as a random building between the residential list */
			living_place <- one_of(residential_buildings);
			/*We assign their working place as a random building in the working buildings */
			working_place <- one_of(industrial_buildings);
			/*We assume that all the locals will begin resting */
			objective <- "resting";
			/*We assign their location as inside their living place */
			location <- any_location_in (living_place);
			/*We assign their color as yellow */
			color <-  #yellow;
			/*We recover the list of recreative buildings */
			ocio <- recreative_buildings;
			/*We recover the list of evacuation points */
			evacuation_points <- extraction;
		}
		/*We create a certain number of tourists*/
		create turist number: nb_turists_init {
			/*We assume the tourists are going to be walking so their velocity will be a random number between the maximum an the minimum */
			speed <- rnd(min_speed_walk, max_speed_walk);
			/*We assign their hotel as a random building between the host buildings */
			hotel <- one_of(host_buildings);
			/*We assume they will start resting */
			objective <- "resting";
			/*We assign their first location as in home */
			location <- any_location_in(hotel);
			/*We recover the list of tourist centres */
			turism <- turism_buildings;
			/*We recover the list of recreative buildings */
			ocio <- recreative_buildings;
			/*We recover the list of evacuation points */
			evacuation_points <- extraction;
		}
		
	}
}

/*We define the building species */
species building {
	/*We recover the string variable type */
	string type;
	/*We recover the dummy variables Turismo, Ocio, Residencial, Trabajo and Host */
	int Turismo;
	int Ocio;
	int Residencial;
	int Trabajo; 
	int Host;
	/*We define that their color will be gray, if not defined previously */
	rgb color <- #gray;
	/*We define their aspect*/
	aspect base {
		/*Their shape will be as in the shape file and their color will be the defined previously */
		draw shape color: color ;
	}
}

/*We define the road species */
species road  {
	/*We define their color as black */
	rgb color <- #black ;
	int congestion <- 0;
	aspect base {
		/*Their shape will be adjusted to the one in the shape_file and their color will be black */
		draw shape color: color ;
	}
}

/*We define their the people agents */
species people skills:[moving] {
	/*We initialize a variable as a list of recreative buildings */
	list<building> ocio;
	list<point> evacuation_points;
	/*We assume all the agents will start walking*/
	string transport <- "pedestrian";
	/* We assign their objective as a string variable */
	string objective; 
	/*We create a pointing variable wich will begin being null */
	point the_target <- nil ;
	road street <- nil;
	
	reflex change_street when: street != current_edge and street != nil and current_edge != nil{
		street.congestion <- street.congestion-1;
		street <- current_edge;
		street.congestion <- street.congestion+1;
	}
	
	reflex begin_street when: street = nil and current_edge != nil{
		street <- current_edge;
		street.congestion <- street.congestion+1;
	}
	
	reflex end_street when: street != nil and current_edge = nil{
		street.congestion <- street.congestion-1;
		street <- current_edge;
	}
	
	reflex evacuated when: location = the_target and objective="evacuating"{
		do die;
	}
	
	/*We generate a reflex that will allow the agent to move through the graph when the target is not null*/
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	/*We generate a reflex in which at certain moment, the objective will change to evacuating and the 
	 * target will point to the closest evacuation point */	
	reflex evacuate when: current_date >= evacuation_start{
		the_target <- evacuation_points closest_to self;
		objective <- "evacuating";
	}
	
	/*We generate a reflex in which we observe if the agent can be evacuated. In other case, we will remove the agent */	
	reflex can_be_evacuated when: objective = "evacuating" and current_path = nil{
		do die;
	}
}

/*We define the local agents */
species locals parent: people{
	/*We recover their color */
	rgb color;
	/*We recover their living place */
	building living_place <- nil ;
	/*We recover their working place*/
	building working_place <- nil ;
	/*We recover their work start time*/
	int start_work ;
	/*We recover their work end time */
	int end_work  ;
	
	/*We generate a reflex which will change their moving rate if the person uses a vehicle */
	/*The condition is that the person is at home, they are a pedestrian and a random porcentage don't excede the probability of using a car */
	reflex using_car when: objective = "resting" and rnd(0.00, 1.00) <= pr_drivers and transport = "pedestrian"{
		/*In this case, the velocity changes to a random number between the minimal and maximal for vehicles */
		speed <- rnd(min_speed_drive, max_speed_drive);
		/*Its color will change to red */
		color <- #red;
		/*We will change the transport variable to driver */
		transport <- "driver";
	}
	
	/*We generate a reflex that will change their moving rate if the person is walking */
	/*The condition is that the person is at home, they are a driver and a random porcentage excedes the probability of using a car*/
	reflex walking when: objective = "resting" and rnd(0.00, 1.00) > pr_drivers and transport = "driver"{
		/*In this case, the velocity changes to a random number between the minimal and maximal for pedestrians */
		speed <- rnd(min_speed_walk, max_speed_walk);
		/*Its color will change to yellow */
		color <- #yellow;
		/*We will change the transport variable to pedestrian */
		transport <- "pedestrian";
	}
	
	/*We generate a reflex in which at certain time, the objective will change from resting or chilling to working and the 
	 * target will point to the person working place */	
	reflex time_to_work when: current_date.hour >= start_work and (objective = "resting" or objective = "chilling"){
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
	
	/*We generate a reflex in which at certain time, the objective will change from resting or chilling to working and the 
	 * target will point to the person living place */	
	reflex time_to_go_home when: current_date.hour >= end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	
		
	reflex tiempo_de_ocio when: objective = "resting" and rnd(0.0, 1.0) < 0.3 and current_date.hour < 20 and current_date.hour > 10{
		objective <- "chilling";
		the_target <- any_location_in(one_of(ocio));
	}
	
	/*We generate a reflex in which at certain time, the objective will change from resting or chilling to working and the 
	 * target will point to the person working place */
	reflex time_to_rest when: objective = "chilling" and current_date.hour > 20{
		objective <- "resting";
		the_target <- any_location_in (living_place);
	}
	
	
	aspect base {
		draw circle(30) color: color border: #black;
	}
}

species turist parent: people{
	rgb color <- rgb ([255, 0, 128]);
	list<building> turism;
	float hora_ini <- rnd(6.0, 11.0);
	float hora_fin <- rnd(20.0, 23.0);
	building hotel;
	float hora_movimiento <- hora_ini;
	
	/*We generate a reflex in which at certain time, the objective will change from resting to turism and the 
	 * target will point to any tourist center */
	reflex time_to_do_turism when: objective = "resting" and current_date.hour >= hora_ini{
		objective <- "turism";
		the_target <- any_location_in(one_of(turism));
		hora_movimiento <- hora_ini + rnd(1.0, 4.0); /*El random es para el tiempo de visita a un edificio */
	}
	
	/*We generate a reflex in which at certain time, the objective will change from tourist to resting and the 
	 * target will point to the person resting place */
	reflex time_to_go_host when: current_date.hour >= hora_fin and objective = "turism"{
		objective <- "resting";
		the_target <- any_location_in(hotel);
		hora_movimiento <- hora_ini;
	}
	
	/*We generate a reflex in which at certain time, the objective will change from resting or chilling to working and the 
	 * target will point to the person working place */
	reflex change_turism when: current_date.hour >= hora_movimiento and objective = "turism"{
		the_target <- any_location_in(one_of(turism));
		hora_movimiento <- hora_movimiento + rnd(1.0, 4.0);
	}
	
	aspect base {
		draw circle(30) color: color border: #black;
	}
}


experiment basic_model type: gui {
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;	
	parameter "Number of local people" var: nb_locals_init category: "People";
	parameter "Number of turist people" var: nb_turists_init category: "People";
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed walking" var: min_speed_walk category: "People" min: 0.1 #km/#h ;
	parameter "maximal speed walking" var: max_speed_walk category: "People" max: 10 #km/#h;
	parameter "minimal speed driving" var: min_speed_drive category: "People" min: 25 #km/#h ;
	parameter "maximal speed driving" var: max_speed_drive category: "People" max: 120 #km/#h;
	parameter "step" var: step category: "General" min: 1 #mn max: 30 #mn;
	parameter "Evacuation time" var: evacuation_start category: "General";
	
	output {
		display city_display type: opengl {
			species building aspect: base ;
			species road aspect: base ;
			species locals aspect: base ;
			species turist aspect: base ;
		}
		display chart_display refresh: every(1#cycles) {
			chart "Vehicle ammount" type: histogram background: #lightgray size: {1, 0.33} position: {0, 0}{
				data "Static" value: locals count (each.the_target=nil) color: #magenta;
				data "Pedestrian" value: locals count (each.the_target!=nil and each.transport = "pedestrian") color: #blue;
				data "Driver" value: locals count (each.the_target!=nil and each.transport = "driver") color: #yellow;
			}
			
			chart "Locals status" type: pie style: exploded size: {1, 0.33} position: {0, 0.33}{
				data "Working" value: locals count (each.objective="working") color: #orange;
				data "Resting" value: locals count (each.objective="resting") color: #green;
				data "Chilling" value: locals count (each.objective="chilling") color: #blue;
			}
			chart "Congestion in streets" type: pie background: #lightgray size:{1, 0.33} position: {0, 0.66}{
				datalist (distribution_of(road collect each.congestion, 10, 0, 10) at "legend") value: (distribution_of(road collect each.congestion, 10, 0, 10) at "values");
			}
		}
		
	}
}


    
