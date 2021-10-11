#include <SDL.h>
#include <SDL_events.h>
#include <SDL_stdinc.h>
//#include <stdio.h>

/* Very cheap system to prevent accessing perl context concurrently in multiple
 * threads */
SDL_bool done = SDL_FALSE;
Uint32 _interval = 0;
void *_param = 0;

SDL_TimerCallback timer_cb;
SDL_mutex *timer_lock, *mixer_lock;
SDL_cond *timer_cond, *mixer_cond;

// #include <SDL_mixer.h>
// Implicit declaration of Mix_SetPostMix?
typedef void my_mix_func(void *, Uint8 *, int);
my_mix_func *mixer_cb;
Uint8 *_streamX;

void Bundle_SDL_Wrap_BEGIN(const char *package, int argc, const char *argv[]) {
  // fprintf(stderr, "# Bundle_SDL_Wrap_BEGIN( %s, ... )", package);
  if (timer_lock == NULL)
    timer_lock = SDL_CreateMutex();
  if (timer_cond == NULL)
    timer_cond = SDL_CreateCond();
  if (mixer_lock == NULL)
    mixer_lock = SDL_CreateMutex();
  if (mixer_cond == NULL)
    mixer_cond = SDL_CreateCond();
}
void Bundle_SDL_Wrap_END(const char *package) {
  // fprintf(stderr, "# Bundle_SDL_Wrap_END( %s )", package);

  SDL_DestroyMutex(timer_lock);
  SDL_DestroyCond(timer_cond);

  SDL_DestroyMutex(mixer_lock);
  SDL_DestroyCond(mixer_cond);
}

static const char *DisplayOrientationName(int orientation) {
  switch (orientation) {
#define CASE(X)                                                                \
  case SDL_ORIENTATION_##X:                                                    \
    return #X
    CASE(UNKNOWN);
    CASE(LANDSCAPE);
    CASE(LANDSCAPE_FLIPPED);
    CASE(PORTRAIT);
    CASE(PORTRAIT_FLIPPED);
#undef CASE
  default:
    return "???";
  }
}

void Bundle_SDL_PrintEvent(SDL_Event *event) {
  if ((event->type == SDL_MOUSEMOTION) || (event->type == SDL_FINGERMOTION)) {
    /* Mouse and finger motion are really spammy */
    return;
  }

  switch (event->type) {
  case SDL_DISPLAYEVENT:
    switch (event->display.event) {
    case SDL_DISPLAYEVENT_ORIENTATION:
      SDL_Log("SDL EVENT: Display %u changed orientation to %s",
              event->display.display,
              DisplayOrientationName(event->display.data1));
      break;
    default:
      SDL_Log("SDL EVENT: Display %u got unknown event 0x%4.4x",
              event->display.display, event->display.event);
      break;
    }
    break;
  case SDL_WINDOWEVENT:
    switch (event->window.event) {
    case SDL_WINDOWEVENT_SHOWN:
      SDL_Log("SDL EVENT: Window %u shown", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_HIDDEN:
      SDL_Log("SDL EVENT: Window %u hidden", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_EXPOSED:
      SDL_Log("SDL EVENT: Window %u exposed", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_MOVED:
      SDL_Log("SDL EVENT: Window %u moved to %d,%d", event->window.windowID,
              event->window.data1, event->window.data2);
      break;
    case SDL_WINDOWEVENT_RESIZED:
      SDL_Log("SDL EVENT: Window %u resized to %dx%d", event->window.windowID,
              event->window.data1, event->window.data2);
      break;
    case SDL_WINDOWEVENT_SIZE_CHANGED:
      SDL_Log("SDL EVENT: Window %u changed size to %dx%d",
              event->window.windowID, event->window.data1, event->window.data2);
      break;
    case SDL_WINDOWEVENT_MINIMIZED:
      SDL_Log("SDL EVENT: Window %u minimized", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_MAXIMIZED:
      SDL_Log("SDL EVENT: Window %u maximized", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_RESTORED:
      SDL_Log("SDL EVENT: Window %u restored", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_ENTER:
      SDL_Log("SDL EVENT: Mouse entered window %u", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_LEAVE:
      SDL_Log("SDL EVENT: Mouse left window %u", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_FOCUS_GAINED:
      SDL_Log("SDL EVENT: Window %u gained keyboard focus",
              event->window.windowID);
      break;
    case SDL_WINDOWEVENT_FOCUS_LOST:
      SDL_Log("SDL EVENT: Window %u lost keyboard focus",
              event->window.windowID);
      break;
    case SDL_WINDOWEVENT_CLOSE:
      SDL_Log("SDL EVENT: Window %u closed", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_TAKE_FOCUS:
      SDL_Log("SDL EVENT: Window %u take focus", event->window.windowID);
      break;
    case SDL_WINDOWEVENT_HIT_TEST:
      SDL_Log("SDL EVENT: Window %u hit test", event->window.windowID);
      break;
    default:
      SDL_Log("SDL EVENT: Window %u got unknown event 0x%4.4x",
              event->window.windowID, event->window.event);
      break;
    }
    break;
  case SDL_KEYDOWN:
    SDL_Log("SDL EVENT: Keyboard: key pressed  in window %u: scancode 0x%08X = "
            "%s, keycode 0x%08x = %s",
            event->key.windowID, event->key.keysym.scancode,
            SDL_GetScancodeName(event->key.keysym.scancode),
            event->key.keysym.sym, SDL_GetKeyName(event->key.keysym.sym));
    break;
  case SDL_KEYUP:
    SDL_Log("SDL EVENT: Keyboard: key released in window %u: scancode 0x%08X = "
            "%s, keycode 0x%08x = %s",
            event->key.windowID, event->key.keysym.scancode,
            SDL_GetScancodeName(event->key.keysym.scancode),
            event->key.keysym.sym, SDL_GetKeyName(event->key.keysym.sym));
    break;
  case SDL_TEXTEDITING:
    SDL_Log("SDL EVENT: Keyboard: text editing \"%s\" in window %u",
            event->edit.text, event->edit.windowID);
    break;
  case SDL_TEXTINPUT:
    SDL_Log("SDL EVENT: Keyboard: text input \"%s\" in window %u",
            event->text.text, event->text.windowID);
    break;
  case SDL_KEYMAPCHANGED:
    SDL_Log("SDL EVENT: Keymap changed");
    break;
  case SDL_MOUSEMOTION:
    SDL_Log("SDL EVENT: Mouse: moved to %d,%d (%d,%d) in window %u",
            event->motion.x, event->motion.y, event->motion.xrel,
            event->motion.yrel, event->motion.windowID);
    break;
  case SDL_MOUSEBUTTONDOWN:
    SDL_Log("SDL EVENT: Mouse: button %d pressed at %d,%d with click count %d "
            "in window %u",
            event->button.button, event->button.x, event->button.y,
            event->button.clicks, event->button.windowID);
    break;
  case SDL_MOUSEBUTTONUP:
    SDL_Log("SDL EVENT: Mouse: button %d released at %d,%d with click count %d "
            "in window %u",
            event->button.button, event->button.x, event->button.y,
            event->button.clicks, event->button.windowID);
    break;
  case SDL_MOUSEWHEEL:
    SDL_Log("SDL EVENT: Mouse: wheel scrolled %d in x and %d in y (reversed: "
            "%u) in window %u",
            event->wheel.x, event->wheel.y, event->wheel.direction,
            event->wheel.windowID);
    break;
  case SDL_JOYDEVICEADDED:
    SDL_Log("SDL EVENT: Joystick index %d attached", event->jdevice.which);
    break;
  case SDL_JOYDEVICEREMOVED:
    SDL_Log("SDL EVENT: Joystick %d removed", event->jdevice.which);
    break;
  case SDL_JOYBALLMOTION:
    SDL_Log("SDL EVENT: Joystick %d: ball %d moved by %d,%d",
            event->jball.which, event->jball.ball, event->jball.xrel,
            event->jball.yrel);
    break;
  case SDL_JOYHATMOTION: {
    const char *position = "UNKNOWN";
    switch (event->jhat.value) {
    case SDL_HAT_CENTERED:
      position = "CENTER";
      break;
    case SDL_HAT_UP:
      position = "UP";
      break;
    case SDL_HAT_RIGHTUP:
      position = "RIGHTUP";
      break;
    case SDL_HAT_RIGHT:
      position = "RIGHT";
      break;
    case SDL_HAT_RIGHTDOWN:
      position = "RIGHTDOWN";
      break;
    case SDL_HAT_DOWN:
      position = "DOWN";
      break;
    case SDL_HAT_LEFTDOWN:
      position = "LEFTDOWN";
      break;
    case SDL_HAT_LEFT:
      position = "LEFT";
      break;
    case SDL_HAT_LEFTUP:
      position = "LEFTUP";
      break;
    }
    SDL_Log("SDL EVENT: Joystick %d: hat %d moved to %s", event->jhat.which,
            event->jhat.hat, position);
  } break;
  case SDL_JOYBUTTONDOWN:
    SDL_Log("SDL EVENT: Joystick %d: button %d pressed", event->jbutton.which,
            event->jbutton.button);
    break;
  case SDL_JOYBUTTONUP:
    SDL_Log("SDL EVENT: Joystick %d: button %d released", event->jbutton.which,
            event->jbutton.button);
    break;
  case SDL_CONTROLLERDEVICEADDED:
    SDL_Log("SDL EVENT: Controller index %d attached", event->cdevice.which);
    break;
  case SDL_CONTROLLERDEVICEREMOVED:
    SDL_Log("SDL EVENT: Controller %d removed", event->cdevice.which);
    break;
  case SDL_CONTROLLERAXISMOTION:
    /*SDL_Log("SDL EVENT: Controller %d axis %d ('%s') value: %d",
        event->caxis.which,
        event->caxis.axis,
        ControllerAxisName((SDL_GameControllerAxis)event->caxis.axis),
        event->caxis.value);*/
    break;
  case SDL_CONTROLLERBUTTONDOWN:
    /*SDL_Log("SDL EVENT: Controller %dbutton %d ('%s') down",
        event->cbutton.which, event->cbutton.button,
        ControllerButtonName((SDL_GameControllerButton)event->cbutton.button));*/
    break;
  case SDL_CONTROLLERBUTTONUP:
    /*SDL_Log("SDL EVENT: Controller %d button %d ('%s') up",
        event->cbutton.which, event->cbutton.button,
        ControllerButtonName((SDL_GameControllerButton)event->cbutton.button));*/
    break;
  case SDL_CLIPBOARDUPDATE:
    SDL_Log("SDL EVENT: Clipboard updated");
    break;

  case SDL_FINGERMOTION:
    SDL_Log("SDL EVENT: Finger: motion touch=%ld, finger=%ld, x=%f, y=%f, "
            "dx=%f, dy=%f, pressure=%f",
            (long)event->tfinger.touchId, (long)event->tfinger.fingerId,
            event->tfinger.x, event->tfinger.y, event->tfinger.dx,
            event->tfinger.dy, event->tfinger.pressure);
    break;
  case SDL_FINGERDOWN:
  case SDL_FINGERUP:
    SDL_Log("SDL EVENT: Finger: %s touch=%ld, finger=%ld, x=%f, y=%f, dx=%f, "
            "dy=%f, pressure=%f",
            (event->type == SDL_FINGERDOWN) ? "down" : "up",
            (long)event->tfinger.touchId, (long)event->tfinger.fingerId,
            event->tfinger.x, event->tfinger.y, event->tfinger.dx,
            event->tfinger.dy, event->tfinger.pressure);
    break;
  case SDL_DOLLARGESTURE:
    SDL_Log("SDL_EVENT: Dollar gesture detect: %ld",
            (long)event->dgesture.gestureId);
    break;
  case SDL_DOLLARRECORD:
    SDL_Log("SDL_EVENT: Dollar gesture record: %ld",
            (long)event->dgesture.gestureId);
    break;
  case SDL_MULTIGESTURE:
    SDL_Log("SDL_EVENT: Multi gesture fingers: %d", event->mgesture.numFingers);
    break;

  case SDL_RENDER_DEVICE_RESET:
    SDL_Log("SDL EVENT: render device reset");
    break;
  case SDL_RENDER_TARGETS_RESET:
    SDL_Log("SDL EVENT: render targets reset");
    break;

  case SDL_APP_TERMINATING:
    SDL_Log("SDL EVENT: App terminating");
    break;
  case SDL_APP_LOWMEMORY:
    SDL_Log("SDL EVENT: App running low on memory");
    break;
  case SDL_APP_WILLENTERBACKGROUND:
    SDL_Log("SDL EVENT: App will enter the background");
    break;
  case SDL_APP_DIDENTERBACKGROUND:
    SDL_Log("SDL EVENT: App entered the background");
    break;
  case SDL_APP_WILLENTERFOREGROUND:
    SDL_Log("SDL EVENT: App will enter the foreground");
    break;
  case SDL_APP_DIDENTERFOREGROUND:
    SDL_Log("SDL EVENT: App entered the foreground");
    break;
  case SDL_DROPBEGIN:
    SDL_Log("SDL EVENT: Drag and drop beginning");
    break;
  case SDL_DROPFILE:
    SDL_Log("SDL EVENT: Drag and drop file: '%s'", event->drop.file);
    break;
  case SDL_DROPTEXT:
    SDL_Log("SDL EVENT: Drag and drop text: '%s'", event->drop.file);
    break;
  case SDL_DROPCOMPLETE:
    SDL_Log("SDL EVENT: Drag and drop ending");
    break;
  case SDL_QUIT:
    SDL_Log("SDL EVENT: Quit requested");
    break;
  case SDL_USEREVENT:
    SDL_Log("SDL EVENT: User event %d", event->user.code);
    break;
  default:
    SDL_Log("Unknown event 0x%4.4u", event->type);
    break;
  }
}

void Bundle_SDL_Yield() {
  // fprintf(stderr, "# Bundle_SDL_Yield( )");

  /*if (lock == NULL)
          return;
  if (cond == NULL)
          return;*/
  if (timer_cb != NULL) {

    // SDL_Log("<Bundle_SDL_Yield> (%u)", _interval);
    SDL_LockMutex(timer_lock);
    // SDL_Log("399");
    _interval = timer_cb(_interval, NULL); // Call cb and set global int for other
    // thread
    // SDL_Log("402");
    timer_cb = NULL; // Clear it so we don't repeat this cb without cause
    // SDL_Log("404");
    SDL_UnlockMutex(timer_lock);
    // SDL_Log("406");
    SDL_CondSignal(timer_cond);
    // SDL_Log("</Bundle_SDL_Yield>");
  }
}

Uint32 c_callback(Uint32 interval, void *param) {
  // fprintf(stderr, "# c_callback( %d, ... )", interval);
  // return interval;
  // SDL_Log("<c_callback> (%u)", interval);
  /*if (lock == NULL)
          return 0;
  if (cond == NULL)
          return 0;
  if (param == NULL)
          return 0;*/
  done = SDL_FALSE;
  // SDL_Log("420");
  SDL_LockMutex(timer_lock);
  // SDL_Log("422");
  timer_cb = (SDL_TimerCallback)param;
  // SDL_Log("424");
  _interval = interval;
  //_param = param;
  SDL_CondWait(timer_cond, timer_lock); // Wait for main thread to return from callback
  // SDL_Log("428");
  SDL_UnlockMutex(timer_lock);
  // SDL_Log("430");
  SDL_CondSignal(timer_cond);
  // SDL_Log("</c_callback> (%u)", _interval);
  done = SDL_TRUE;
  return _interval;
}

SDL_TimerID Bundle_SDL_AddTimer(int delay, SDL_TimerCallback cb, void *params) {
  // fprintf(stderr, "# Bundle_SDL_AddTimer( %d, ... )", delay);
  return SDL_AddTimer(delay, c_callback, cb);
}

SDL_bool Bundle_SDL_RemoveTimer(SDL_TimerID id) {
  // fprintf(stderr, "# Bundle_SDL_RemoveTimer( %d )", id);
  return SDL_RemoveTimer(id);
}

void wrap_mix_func(void *udata, Uint8 *_stream, int len) {
  if (mixer_cb != NULL) {
    _streamX = (Uint8 *)SDL_realloc(_stream, len);
    mixer_cb(udata, _stream, len);
    for (int i = 0; i < len; i++)
      _stream[i] = _streamX[i];
  }
}

void Bundle_Mix_mix_cb_return(Uint8 *sample, int len) {
  for (int i = 0; i < len; i++)
    _streamX[i] = sample[i];
}

void Bundle_Mix_SetPostMix(my_mix_func mix_func, void *arg) {
  mixer_cb = mix_func;
  Mix_SetPostMix(wrap_mix_func, arg);
}
