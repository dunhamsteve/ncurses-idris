IDRIS := idris2
SHAREDLIB_INSTALLDIR = `${IDRIS} --libdir`/ncurses-idris/lib

TARGET = ncurses-idris

LDFLAGS = -lncurses

DYLIB_WORKAROUND = @echo Skipping Darwin workaround
ifeq (,$(findstring darwin,$(OSTYPE)))
 DYLIB_WORKAROUND = cp "${SHAREDLIB_INSTALLDIR}/${TARGET}" "${SHAREDLIB_INSTALLDIR}/${TARGET}.dylib"
endif

SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)

all: idris $(TARGET)$(SHLIB_SUFFIX)

$(TARGET)$(SHLIB_SUFFIX): $(OBJS)
	$(CC) -shared $(LDFLAGS) -o $@ $^


-include $(DEPS)

%.d: %.c
	@$(CPP) $(CFLAGS) $< -MM -MT $(@:.d=.o) >$@

.PHONY: idris

idris:
	idris2 --build ncurses-idris.ipkg

.PHONY: clean

clean:
	rm -f $(OBJS) $(TARGET)$(SHLIB_SUFFIX)
	rm -rf ./build

cleandep: clean
	rm -f $(DEPS)

.PHONY: install

install:
	idris2 --install ncurses-idris.ipkg
	@if ! [ -d $(SHAREDLIB_INSTALLDIR) ]; then mkdir -p $(SHAREDLIB_INSTALLDIR); fi
	install $(TARGET)$(SHLIB_SUFFIX) $(wildcard *.h) $(SHAREDLIB_INSTALLDIR)
	$(DYLIB_WORKAROUND)
