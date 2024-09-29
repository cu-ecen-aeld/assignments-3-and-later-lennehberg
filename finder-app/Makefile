# a simple make file to make writer from writer.c, support cross compilation
# using the CROSS_COMPILE varialbe
CC := $(if $(CROSS_COMPILE), $(CROSS_COMPILE)gcc, gcc)
CFLAGS = -Wall -Wextra
LDFLAGS = 

# Target- writer
TARGET = writer
SRC = writer.c
OBJ = $(SRC:.c=.o)


$(TARGET) : $(OBJ)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJ)

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm $(TARGET) $(OBJ)
