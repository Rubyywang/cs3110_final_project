type t = {
  character : string;
  character_hp : int;
  enemy : string;
  enemy_hp : int;
}

let character_turn bat atk =
  {
    character = bat.character;
    character_hp = bat.character_hp;
    enemy = bat.enemy;
    enemy_hp = bat.enemy_hp - 10;
  }

let enemy_turn bat =
  {
    character = bat.character;
    character_hp = bat.character_hp - 10;
    enemy = bat.enemy;
    enemy_hp = bat.enemy_hp;
  }

let character bat = bat.character