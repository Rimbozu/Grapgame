library game;

import 'dart:html';
import 'dart:math';
import 'package:dartemis/dartemis.dart';

part 'src/components.dart';

const WIDTH = 1000;
const HEIGHT = 600;
const SPIELER = 'spieler';
const FOOD = 'food';
const OBJEKT = 'objekt';
const SPSIZE = 12;
const MAXSPEED = 5;

World welt;
var canvas = querySelector('canvas'); //canvas = Leinwand, das spielefenster

num score = 0;
num life = 3;

Random zufall = new Random();

void main() {
  
    
    canvas.width=WIDTH;
    canvas.height=HEIGHT;
    new Game(canvas).start();   
  
}

class Game{
  CanvasElement canvas;
  
  Game(this.canvas);
  
  start(){
    TagManager tm = new TagManager();
    
    welt = new World();
   
    var spieler = welt.createEntity();
    spieler.addComponent(new Colour("red"));
    spieler.addComponent(new Position(500, 200));
    spieler.addComponent(new Speed(0, 0));
    spieler.addComponent(new Size(SPSIZE, SPSIZE));
    spieler.addToWorld();
    
    tm.register(spieler, SPIELER);
    
    var food = createFood(250, 500);
    tm.register(food, FOOD);
    
    var objekt = createObjekt(1000, 300, -7, 0, 10, 130, "black");
    tm.register(objekt, OBJEKT);
    
    welt.addManager(tm);
    welt.addSystem(new InputSystem());
    welt.addSystem(new PositionSystem());
    welt.addSystem(new MovementSystem()); // Movement system erstellt bewegung
    welt.addSystem(new RenderSystem(canvas)); //render system mahlt (spieler)
    welt.initialize();

    gameloop(null);
  }

  
  
  gameloop(_){
    welt.process();
    window.animationFrame.then(gameloop);
  }
}


class InputSystem extends VoidEntitySystem {
  Speed sp; 
  Map<int,bool> keypressed = new Map<int,bool>();
  
  initialize(){
    TagManager tm = world.getManager(TagManager); 
    var spieler = tm.getEntity(SPIELER);
    var sm = new ComponentMapper<Speed>(Speed, world); 
    sp = sm.get(spieler);
    window.onKeyDown.listen((event)=>keypressed[event.keyCode]=true);
    window.onKeyUp.listen((event)=>keypressed[event.keyCode]=false);
  }
 
  processSystem(){
    if (keypressed[KeyCode.UP] == true){
      if (-sp.y <=MAXSPEED) {
        sp.y -= 1;
      }
    }
    if (keypressed[KeyCode.DOWN] == true){
      if (sp.y <=MAXSPEED) {
        sp.y += 1;
      }
    }
    if (keypressed[KeyCode.LEFT] == true){
      if (-sp.x <=MAXSPEED) {
        sp.x -= 1;
      }
    }
    if (keypressed[KeyCode.RIGHT] == true){
      if (sp.x <=MAXSPEED) {
        sp.x += 1;
      }
    }
    if (keypressed[KeyCode.SPACE] == true){
      sp.x = 0;
      sp.y = 0;
    }
  }
}


class PositionSystem extends VoidEntitySystem {
  CanvasElement canvas;
  Position sl, fd, obj;
  Speed slp;
  ComponentMapper<Position> pm;
  ComponentMapper<Speed> sm;
  
  initialize(){

    TagManager tm = world.getManager(TagManager);
    var spieler = tm.getEntity(SPIELER);
    var food = tm.getEntity(FOOD);
    var objekt = tm.getEntity(OBJEKT);
    pm = new ComponentMapper<Position>(Position, world);
    sm = new ComponentMapper<Speed>(Speed, world); 
    slp = sm.get(spieler);
    sl = pm.get(spieler);
    fd = pm.get(food);
    obj = pm.get(objekt);
    }
  
  processSystem(){
    TagManager tm = world.getManager(TagManager); 
    
    num counter=score%5;
    num foodcounter=0;
    if (foodcounter==0){
      testHitFood(tm, fd.x, fd.y, sl.x, sl.y, foodcounter);
    }
      
    
    if ( (obj.x+10 >= sl.x+6 && sl.x+6 >= obj.x) && (obj.y+130 >= sl.y+6 && sl.y+6 >= obj.y)){
      life-=1;
      sl.x= 100;
      sl.y= 100;
      slp.x= 0;
      slp.y= 0;
    }
    
    if (counter==0){
      fd.x=300;
      fd.y=300;
    }
    if (counter==1){
      fd.x=50;
      fd.y=100;
    }
    if (counter==2){
      fd.x=400;
      fd.y=300;
    }
    if (counter==3){
      fd.x=300;
      fd.y=400;
    }
    if (counter==4){
      fd.x=490;
      fd.y=120;
    }
  }
  
}

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Position> pm;
  ComponentMapper<Speed> sm;
  MovementSystem() :super(Aspect.getAspectForAllOf([Position, Speed]));
  
  initialize(){
    pm = new ComponentMapper<Position>(Position, world); 
    sm = new ComponentMapper<Speed>(Speed, world); 
  }
  
  processEntity(Entity e){
    Position pos = pm.get(e);
    Speed sp = sm.get(e);
    pos.x += sp.x;
    pos.y += sp.y;
    if (zufall.nextBool()){
      if(pos.x <= 0){
        pos.x += WIDTH ;
      }
      if(pos.x >= WIDTH){
        pos.x -= WIDTH;  
      }
      if(pos.y <= 0){
        pos.y += HEIGHT;
      }
      if(pos.y >= HEIGHT){
        pos.y -= HEIGHT;
      }
    }
    else {
      if(pos.x <= 0){
        sp.x = -sp.x ;
      }
      if(pos.x >= WIDTH){
        sp.x = -sp.x;
      }
      if(pos.y <= 0){
        sp.y = -sp.y;
      }
      if(pos.y >= HEIGHT){
        sp.y = -sp.y;
      }
    }  
  }
}

class RenderSystem extends EntityProcessingSystem {
  CanvasElement canvas;
  ComponentMapper<Colour> cm;
  ComponentMapper<Position> pm;
  ComponentMapper<Size> sim;
  RenderSystem(this.canvas) :super(Aspect.getAspectForAllOf([Position, Size, Colour]));
  
  initialize(){
    pm = new ComponentMapper<Position>(Position, world);
    sim = new ComponentMapper<Size>(Size, world);
    cm = new ComponentMapper<Colour>(Colour, world);
  }
  
  processEntity(Entity e){
    Position pos = pm.get(e);
    Size bp = sim.get(e);
    Colour fp = cm.get(e);
    canvas.context2D.fillStyle=fp.farbe;
    canvas.context2D.fillRect(pos.x, pos.y, bp.x, bp.y);
  }
  
  begin(){
    canvas.context2D.clearRect(0, 0, 1000, 600);
    canvas.context2D.fillText("Score:" , 900, 550);
    canvas.context2D.fillText(score.toString() , 970, 550);
    canvas.context2D.fillText("Lifes:" , 900, 570);
    canvas.context2D.fillText(life.toString() , 970, 570);
  }
}

Entity createObjekt(num height, num width, num spx, num spy, num six, num siy, String color) {
  var objekt = welt.createEntity();
  objekt.addComponent(new Colour(color));
  objekt.addComponent(new Position(height, width));
  objekt.addComponent(new Speed(spx, spy));
  objekt.addComponent(new Size(six, siy));
  objekt.addToWorld(); 
  return objekt;
}

Entity createFood(num height, num width) {
  var food = welt.createEntity();
  food.addComponent(new Colour("green"));
  food.addComponent(new Position(height, width));
  food.addComponent(new Speed(0, 0));
  food.addComponent(new Size(SPSIZE, SPSIZE));
  food.addToWorld(); 
  return food;
}

void testHitFood(TagManager tm , num objx, num objy, num slx, num sly, num counter) {
  
  if ( (objx+10 >= slx && slx >= objx) && (objy+10 >= sly && sly >= objy)){
    score+=1;
    counter+=1;
  }
  
  else{
    if ( (objx+10 >= slx+10 && slx+10 >= objx) && (objy+10 >= sly && sly >= objy)){
      score+=1;
      counter+=1;
    }
    
    else{
      if ( (objx+10 >= slx && slx >= objx) && (objy+10 >= sly+10 && sly+10 >= objy)){
        score+=1;
        counter+=1;
      }
      
      else{
        if ( (objx+10 >= slx+10 && slx+10 >= objx) && (objy+10 >= sly+10 && sly+10 >= objy)){
          score+=1;
          counter+=1;
        } 
      }       
    }      
  }  
} 
  
  
  