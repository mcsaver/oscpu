#include<stdio.h>
#include<errno.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<assert.h>
#include"ex19.h"

int Monster_attack(void *self, int damage)
{
    assert(self != NULL);
    Monster *monster = self;

    printf("You attack %s!\n", monster->_(description));

    monster->hit_points -= damage;

    if (monster->hit_points > 0)
    {
        printf("It is still alive.\n");
        return 0;
    } else
    {
        printf("It is dead!\n");
        return 1;
    }    
}

int Monster_init(void *self)
{
    assert(self != NULL);
    Monster *monster = self;
    monster->hit_points = 10;
    return 1;
}

Object MonsterProto = {
    .init = Monster_init,
    .attack = Monster_attack
};

void *Room_move(void *self, Direction direction)
{
    assert(self != NULL);
    Room *room = self;
    Room *next = NULL;

    if (direction == NORTH && room->north)
    {
        printf("You go north, into:\n");
        next = room->north;
    } else if (direction == SOUTH && room->south)
    {
        printf("You go south, into:\n");
        next = room->south;
    } else if (direction == EAST && room->east)
    {
        printf("You go east, into:\n");
        next = room->east;
    } else if (direction == WEST && room->west)
    {
        printf("You go west, into:\n");
        next = room->west;
    } else
    {
        printf("You can't go that direction");
        next = NULL;
    }
    
    if (next)
    {
        next->_(describe)(next);
    }
    else {
        /* no next room to describe */
    }
    
    return next;
    
}

int Room_attack(void *self, int damage)
{
    assert(self != NULL);
    Room *room = self;
    Monster *monster = room->bad_guy;

    if (monster)
    {
        monster->_(attack)(monster, damage);
        return 1;
    } else
    {
        printf("You flail in the air at nothing. Idiot.\n");
        return 0;
    }
    
}

Object RoomProto = {
    .move = Room_move,
    .attack = Room_attack
};

void *Map_move(void *self, Direction direction)
{
    assert(self != NULL);
    Map *map =self;
    Room *location = map->location;
    Room *next = NULL;

    next = location->_(move)(location, direction);

    if (next)
    {
        map->location = next;
    } else {
        /* location unchanged */
    }
    
    return next;
}

int Map_attack(void *self, int damage)
{
    assert(self != NULL);
    Map *map = self;
    Room *location = map->location;

    return location->_(attack)(location, damage);
}

int Map_init(void *self)
{
    assert(self != NULL);
    Map *map = self;

    // make some rooms for a small map (expanded)
    Room *hall = NEW(Room, "The great Hall");
    assert(hall != NULL);
    Room *throne = NEW(Room, "The throne room");
    assert(throne != NULL);
    Room *arena = NEW(Room, "The arena, with the minoataur");
    assert(arena != NULL);
    Room *kitchen = NEW(Room, "Kitchen, you have the knife now");
    assert(kitchen != NULL);

    /* Additional rooms */
    Room *library = NEW(Room, "The dusty library");
    assert(library != NULL);
    Room *armory = NEW(Room, "The armory, filled with rusty weapons");
    assert(armory != NULL);
    Room *garden = NEW(Room, "A small overgrown garden");
    assert(garden != NULL);

    // put the bad guys in several rooms
    arena->bad_guy = NEW(Monster, "The evil minotaur");
    assert(arena->bad_guy != NULL);

    kitchen->bad_guy = NEW(Monster, "A crazed cook");
    assert(kitchen->bad_guy != NULL);

    library->bad_guy = NEW(Monster, "A ghostly librarian");
    assert(library->bad_guy != NULL);

    armory->bad_guy = NEW(Monster, "An armored guard");
    assert(armory->bad_guy != NULL);

    // setup the map rooms (preserve original connections so tests still work)
    hall->north = throne;
    hall->east = library;

    throne->west = arena;
    throne->east = kitchen;
    throne->south = hall;

    arena->east = throne;
    kitchen->west = throne;

    library->west = hall;
    library->east = armory;
    library->north = garden;

    armory->west = library;
    garden->south = library;

    // start the map and character off in the hall
    map->start = hall;
    map->location = hall;

    return 1;
}

Object MapProto = {
    .init = Map_init,
    .move = Map_move,
    .attack = Map_attack
};

int process_input(Map *game)
{
    assert(game != NULL);
    printf("\n");

    char ch = getchar();
    getchar(); //eat ENTER

    int damage = rand() % 4;

    switch (ch)
    {
    case -1:
        printf("Giving up? You suck.\n");
        return 0;
        break;
    
    case 'n':
        game->_(move)(game, NORTH);
        break;
    
    case 's':
        game->_(move)(game, SOUTH);
        break;

    case 'e':
        game->_(move)(game, EAST);
        break;

    case 'w':
        game->_(move)(game, WEST);
        break;

    case 'a':
        game->_(attack)(game, damage);
        break;
    case 'l':
        printf("You can go:\n");
        if(game->location->north) printf("NORTH\n"); else { }
        if(game->location->south) printf("SOUTH\n"); else { }
        if(game->location->east) printf("EAST\n"); else { }
        if(game->location->west) printf("WEST\n"); else { }
        break;

    default:
        printf("What?: %d\n", ch);
    }
    
    return 1;
}

int main(int argc, char *argv[])
{
    // simple way to setup the randomness
    srand(time(NULL));

    // make our map to work with
    Map *game = NEW(Map, "The Hall of the Minotaur.");

    printf("You enter the ");
    game->location->_(describe)(game->location);

    while (process_input(game))
    {
        /* code */
    }
    
    return 0;

}