int w = 600, h = 600, size = 20;
int trw = w/size, trh = h/size;
int episodes = 100, curr_epi = 0, best = -1, step = 0, sum_step = 0;

int actions = 4, states = size*size, win;
//actions: 0 = up, 1 = down, 2 = left, 3 = right ---deleted, 4 = stay

int maze[][];
//1 = end, 0 = nothing, -1 = penalty, 2 = wall
/*  1 2 0 -1 0
**  0 2 0 0  0
**  0 0 s 0  0
**  0 0 0 -1 0
**  0 0 0 0 -1
** 1 = green(0,255,0), 2 = black(0), -1 = red(255,0,0)
*/

float qtable[][];
//1 for reward, -1 for penalty, -100 for dying
//row*size+column = stateNum

float greed = 0.9, discount = 0.2, learning = 0.8;

int ini_x,ini_y,x,y,win_x,win_y,ini;
//current position
boolean end = false, demo = false, random_gen = true, random_init = true;

void setup(){
  frameRate(10);
  ini_x = 2;
  ini_y = 2;

  ini = y*size+x;
  maze = new int[size][size];
  qtable = new float[states][actions];
  maze_gen();
  respawn();
  
  
  size(1000, 601);
  background(250);
  ellipseMode(RADIUS);
  
  println("start(episode 0)");
}

void respawn(){
  if (random_init) {
    x = (int)random(size);
    y = (int)random(size);
    while (maze[y][x] != 0) {
      x = (int)random(size);
      y = (int)random(size);
    }
  } else {
    x = ini_x;
    y = ini_y;
  }
  step = 0;
}

void maze_gen(){
  if (!random_gen) {
    maze[0][0] = 1;
    maze[0][1] = 2;
    maze[0][3] = -1;
    maze[1][1] = 2;
    maze[3][3] = -1;
    maze[4][1] = 2;
    maze[4][4] = -1;
    win = 0;
    win_x = 0;
    win_y = 0;
  } else {
    int ran_x, ran_y;
    while (win == ini) {
      win_x = (int)random(size);;
      win_y = (int)random(size);;
      win = win_y*size+win_x;
    }
    maze[win_y][win_x] = 1;
    int p = (int)random(size*1.5);
    //println("1"+p);
    p= (p == 0 ? 1 : p);
    for (int i = 0; i < p; i++) {
      ran_x = (int)random(size);
      ran_y = (int)random(size);
      if (maze[ran_y][ran_x] == 0){
        maze[ran_y][ran_x] = -1;
      }
    }
    p = (int)random(5);
    //println("2"+p);
    for (int i = 0; i < p; i++) {
      ran_x = (int)random(size);
      ran_y = (int)random(size);
      if (maze[ran_y][ran_x] == 0){
        maze[ran_y][ran_x] = 2;
      }
    }
    //println("3"+p);
    if (surround()) {
      if (win_x > 0) {
        maze[win_y][win_x-1] = 0;
      }
      if (win_x < size-1) {
        maze[win_y][win_x+1] = 0;
      }
      if (win_y > 0) {
        maze[win_y-1][win_x] = 0;
      }
      if (win_y < size-1) {
        maze[win_y+1][win_x] = 0;
      }
    }
    //println("4"+p);
  }
}

boolean surround() {
  return (win_y == 0 || maze[win_y-1][win_x]!=0)&&(win_x == 0 || maze[win_y][win_x-1]!=0)&&
  (win_y == size-1 || maze[win_y+1][win_x]!=0)&&(win_x == size-1 || maze[win_y][win_x+1]!=0);
}

int argmax(int state){
  float max = qtable[state][0];
  int index = 0, same = 0;
  int mul_index[] = new int[actions];
  for(int i = 1; i < actions; i++){
     if (qtable[state][i] > max){
       index = i;
       max = qtable[state][i];
       same = 0;
       mul_index[0] = i;
     } else if (qtable[state][i] == max){
       same++;
       mul_index[same] = i;
     }
  }
  if (same > 0)
    return mul_index[(int)random(same+1)];
  return index; 
}

float max(int state){
  float max = qtable[state][0];
  for(int i = 1; i < actions; i++){
     if (qtable[state][i] > max)
       max = qtable[state][i];
  }
  return max; 
}

void grid(){
  stroke(0);
  strokeWeight(1);
  line(0,0,w,0);
  line(0,0,0,h);
  for(int i = 1; i <= size; i++){
    line(0,trh*i,w,trh*i);
    line(trw*i,0,trw*i,h);
  }
  strokeWeight(0);
  for(int i = 0; i < size; i++){
    for(int j = 0; j < size; j++){
      if(maze[j][i] == -1){        //penalty
        fill(255,0,0);
      } else if(maze[j][i] == 1){  //reward
        fill(0,255,0);
      } else if(maze[j][i] == 2){  //wall
        fill(0);
      } else {
        fill(250);
      }
      rect(trw*i+1, trh*j+1, trw-1, trh-1);
    }
    fill(0,0,255);
    circle((x+0.5)*trw,(y+0.5)*trh, min(trw, trh)/5);
  }
  text("state #",w+10,15); 
  text("action1",w+10+trw,15);
  text("action2",w+10+2*trw,15);
  text("action3",w+10+3*trw,15);
  text("action4",w+10+4*trw,15);
  fill(250);
  stroke(250);
  int word_h = (h - 16)/(states+2);
  rect(w+10+trw,16,400-trw,(states+3)*word_h+1);
  fill(0);
  for (int i = 0; i < states; i++) {
    text("state "+i,w+10,30+word_h*i);
    for (int j = 0; j < actions; j++) {
       text(""+((int)(qtable[i][j]*1000))/1000.0,w+10+(j+1)*trw,30+word_h*i);
    }
  }
  fill(255,0,0);
  text("episode: "+curr_epi+"\t/\t\tstep: "+step,w+10+trw,30+word_h*states);
  text("best score: "+(best>0?best:"N/A")+"\t/\taverage step: "+sum_step/(curr_epi+1),w+10+trw,30+word_h*(states+1));
}

void draw(){
  if(episodes > curr_epi || demo){
    grid();
    int action = -1;
    int state = y*size+x;
    if (state != win){
      if (random(1) > greed){
        action = (int)(random(actions));
      } else {
        action = argmax(state);
      }
      switch (action) {
        case 0:
          if (y > 0 && maze[y-1][x] != 2)
            y--;
          break;
        case 1:
          if (y < size-1 && maze[y+1][x] != 2)
            y++;
          break;
        case 2:
          if (x > 0 && maze[y][x-1] != 2)
            x--;
          break;
        case 3:
          if (x < size-1 && maze[y][x+1] != 2)
            x++;
          break;
      } 
      qtable[state][action] = (1-learning)*qtable[state][action] + learning*(maze[y][x]+discount*max(y*size+x));
      step++;
      if (!demo) {
        sum_step++;
      }
    } else {
      if (!demo) {
        curr_epi++;
        if (best < 0 || step < best){
          best = step;
        }
        println("moving to episode: ",curr_epi);
      } else {
        demo = false;
        println("demo ended");
      }
      respawn();
    }
  } else if (!end) {
    end = true;
    println("training ended, click to run AI once");
  }
}

void mouseClicked() {
  if (end) {
    demo = true;
    println("demo start");
  }
}
