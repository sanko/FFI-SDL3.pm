#include <SDL_events.h>
#include <SDL_mixer.h>
#include <SDL_stdinc.h>

#include <SDL.h>
#include <SDL_thread.h>
#include <SDL_timer.h>
/*
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>
*/
/* Very cheap system to prevent accessing perl
context concurrently in multiple threads */
Uint32 callbackEventType;
SDL_bool mixer_done = SDL_FALSE;
int timer_done;
typedef void(SDLCALL *mix_func)(void *, Uint8 *, int);
Uint8 *_stream;
SDL_mutex *timer_lock, *mixer_lock;
SDL_cond *timer_cond, *mixer_cond;

void Bundle_SDL_Wrap_BEGIN(const char *package, int argc,
                           const char *argv[]) {
    // fprintf(stderr, "# Bundle_SDL_Wrap_BEGIN( %s, ... )", package);
    if (timer_lock == NULL) timer_lock = SDL_CreateMutex();
    if (timer_cond == NULL) timer_cond = SDL_CreateCond();
    if (mixer_lock == NULL) mixer_lock = SDL_CreateMutex();
    if (mixer_cond == NULL) mixer_cond = SDL_CreateCond();
    callbackEventType = SDL_RegisterEvents(2);
    // 1: timer callback
    // 2: mixer callback
}
void Bundle_SDL_Wrap_END(const char *package) {
    // fprintf(stderr, "# Bundle_SDL_Wrap_END( %s )", package);
    SDL_DestroyMutex(timer_lock);
    SDL_DestroyCond(timer_cond);

    SDL_DestroyMutex(mixer_lock);
    SDL_DestroyCond(mixer_cond);
}

void Bundle_set_stream(Uint8 *in, int len) {
    SDL_memcpy(_stream, in, len);
}

void Bundle_SDL_Yield() {
    SDL_Event event_in;
    SDL_PumpEvents();
    // example taken from https://wiki.libsdl.org/SDL_AddTimer to deal
    // with multithreading problems
    while (SDL_PeepEvents(&event_in, 1, SDL_GETEVENT,
                          callbackEventType,
                          callbackEventType + 4) == 1) {
        if (event_in.type == callbackEventType) {
            SDL_LockMutex(timer_lock);
            SDL_TimerCallback cb =
                ((SDL_TimerCallback)event_in.user.data2);
            timer_done = cb((Uint32)event_in.user.data1, NULL);
            SDL_CondBroadcast(timer_cond);
            SDL_UnlockMutex(timer_lock);
        }
        else if (event_in.type == callbackEventType + 1) {
            mix_func cb = (mix_func)event_in.user.data2;
            cb(NULL, event_in.user.data1, event_in.user.code);
            SDL_CondBroadcast(mixer_cond);
        }
        else {
            SDL_Log("Unhandled callback! Type: %d",
                    event_in.user.code);
        }
    }

    return;
}

Uint32 timer_callback(Uint32 interval, void *param) {
    timer_done = -1;
    //
    SDL_Event event;
    event.type = callbackEventType;
    event.user.code = callbackEventType;
    event.user.data1 = interval;
    event.user.data2 = param;
    SDL_PushEvent(&event);
    //
    SDL_LockMutex(timer_lock);
    while (timer_done == -1) {
        int ret =
            SDL_CondWait(timer_cond, timer_lock); // XXX - Deadlock?
        if (ret == SDL_MUTEX_TIMEDOUT) { timer_done = interval; }
        else if (ret == 0) {
            interval = timer_done;
        }
        else if (ret < 0) {
            // SDL_Log("timer_done == %d | ret == %d [%s]",
            // timer_done, ret, SDL_GetError());
            // timer_done = 0;
        }
    }

    SDL_UnlockMutex(timer_lock);
    SDL_CondSignal(timer_cond);
    return interval;
}

SDL_TimerID Bundle_SDL_AddTimer(int delay, SDL_TimerCallback cb,
                                void *params) {
    return SDL_AddTimer(delay, timer_callback, cb);
}

SDL_bool Bundle_SDL_RemoveTimer(SDL_TimerID id) {
    return SDL_RemoveTimer(id);
}

void wrap_mix_func(void *udata, Uint8 *stream, int len) {
    SDL_LockMutex(mixer_lock);
    mixer_done = SDL_FALSE;
    if (_stream == NULL)
        _stream = SDL_malloc(len);
    else if (sizeof(_stream) != len)
        _stream = SDL_realloc(_stream, len);
    SDL_memcpy(_stream, stream, len);
    //
    SDL_Event event_out, event_in;

    event_out.type = callbackEventType + 1;
    event_out.user.code = len;
    event_out.user.data1 = (void *)stream;
    event_out.user.data2 = udata;
    SDL_PushEvent(&event_out);

    //
    while (mixer_done == SDL_FALSE) {
        int ret = SDL_CondWaitTimeout(
            mixer_cond, mixer_lock,
            100); // XXX: There's a deadlock somewhere
        if (ret == SDL_MUTEX_TIMEDOUT) {
            SDL_memcpy(stream, _stream, len);
            mixer_done = SDL_TRUE;
        }
        else if (ret == 0) {
            SDL_memcpy(stream, _stream, len);
            mixer_done = SDL_TRUE;
        }
        else if (ret < 0) {
            // SDL_Log("mixer_done == %s | ret == %d [%s]",
            // (mixer_done ? "yes" : "no"), ret, SDL_GetError());
            mixer_done = SDL_TRUE;
        }
    }
    // SDL_UnlockMutex(mixer_lock);
    return;
}

void Bundle_Mix_SetPostMix(mix_func cb, void *arg) {
    Mix_SetPostMix(wrap_mix_func, cb);
}
