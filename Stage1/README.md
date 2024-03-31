# El codigo esta divido en difernetes partes:
## 1. Zeropage:
  Aqui se establece las variables que se usaran en la subrutina para determinar las posiciones X y Y del player.

## 2.Code:
  Se usa el irq_handler esto basicamente es un interrupt request,por si hay alguna interrupcion volver de este.

## 3.nmi_handler:
  Esto maneja las interrupciones no enmascarables en el hardware. Configura el registro OAMADDR con el valor $00, lo que indica al PPU que comience a escribir en la OAM (Object Attribute Memory) desde la dirección $00.
  Configura el registro OAMDMA con el valor $02, lo que inicia una transferencia de memoria de CPU a OAM.
  Configura el registro PPUADDR con los valores $00 y $02C0, que apuntan a la tabla de atributos de patrones de sprites (Sprite Pattern Attribute Table) en la VRAM (Video RAM).
  Escribe los datos de los atributos de los sprites en la VRAM.
  Retorna de la interrupción NMI.

## 4. El reset handler 
simplemente es cuando la consola se interrumpio, que se encienda o interrumpa, aqui inicializa los valores X y Y del jugador.

## 5. Despues es la parte principal del codigo el main:
  Lo primero que hice fue definir una paleta, despues se creo el load pallet, aqui como dice el nombre se lodea el palete. Despues se creo un load sprite, se escribieron los nametables, estos son los background basicamente, 
  el primero y segundo nombre es despues de sumar su offset al reg $2000.Ejemplo si tiene un offset(este offset se encuentra en la herramienta NEXXT) de 32a, se escrube en el primer LDA 23(ya que t va a dar 232a) y en el segundo 2a. 
  Despues el siguiente LDX es el numero del tile, te lo da NEXXT tambien. Despues se crea el atribute table, se escoge un AttOff dado por NEXXT y se suma al 2000 de nuevo, dependiend de donde estam localizado depende los bits q debes tocar en el PPUDATA, de ahi es donde entra
  a los palletes, y le asigna los colores.

## 6. draw palyer:
  Esto dibuja el jugador dependiendo de la localizacion es una subrutina pero por ahora no es util. Pero lo que hice fue usar los valores X y Y que se usaron antes para lodear al jugador que es un conjunto de 4 sprites.

## 7.Palletes: 
  Aqui se crean los palletes los primeros 4 son del backgorund y los otros 4 para los sprites.

## 8.sprites:
  Aqui se definen todos los sprites para que el load sprites los use.
  El primer numero es el valor y, el segundo el tile number, el tercero el palete q usara y el cuarto el valor Y.

  Al final añadi el graphics.chr esto es el file de NEXXT con los tiles y todo eso.

  Para actualizarlo y poderlo correr em NEXXT pones en la terminal primero:
    ca65 src/part1.asm
  y depsues:
    ld65 src/part1.o -C nes.cfg -o part1.nes
