#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>

static void log_state(const char *label) {
    printf("sdl-warmup: %s joysticks=%d\n", label, SDL_NumJoysticks());
    fflush(stdout);
}

int main(int argc, char **argv) {
    int wait_ms = 5000;
    if (argc > 1) wait_ms = atoi(argv[1]);

    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI, "1");
    SDL_SetHint("SDL_JOYSTICK_HIDAPI_XBOX_360", "1");
    SDL_SetHint(SDL_HINT_JOYSTICK_MFI, "1");
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_EVENTS) != 0) {
        printf("sdl-warmup: SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *window = SDL_CreateWindow(
        "re7-sdl-warmup",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        320,
        200,
        SDL_WINDOW_HIDDEN
    );
    if (!window) {
        printf("sdl-warmup: window failed: %s\n", SDL_GetError());
    }

    log_state("initial");
    Uint32 start = SDL_GetTicks();
    while ((int)(SDL_GetTicks() - start) < wait_ms) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_CONTROLLERDEVICEADDED) {
                printf("sdl-warmup: controller added idx=%d\n", event.cdevice.which);
                fflush(stdout);
            }
            if (event.type == SDL_JOYDEVICEADDED) {
                printf("sdl-warmup: joystick added idx=%d\n", event.jdevice.which);
                fflush(stdout);
            }
        }
        SDL_Delay(50);
    }

    log_state("final");

    if (window) SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

