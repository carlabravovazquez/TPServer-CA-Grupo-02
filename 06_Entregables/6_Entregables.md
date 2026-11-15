# 6. Entregables: directorios comprimidos y subida al repositorio

## Objetivo

Según la consigna:

1. crear un repositorio en GitHub con un `README.md` que tenga los nombres de los integrantes;
2. subir los directorios **`/root`**, **`/etc`**, **`/opt`**, **`/www_dir`** y **`/backup_dir`**, cada uno comprimido por separado en formato **`.tar.gz`**;
3. subir **`/var`** dividido ("spliteado") en partes pequeñas para que se pueda subir.

## Conceptos previos

- **`tar`.** Empaqueta un directorio completo en un solo archivo. Con `z` lo comprime con gzip; con `c` crea el archivo y con `f` se indica su nombre. Para restaurar se usa `tar xvzf` (Niklas, 2020, p. 62).
- **`split`.** Divide un archivo en porciones según un criterio, por ejemplo el tamaño (Niklas, 2020, p. 83, cuadro 3.1 de filtros).
- **`cat`.** Concatena archivos y muestra el resultado; combinado con `>` sirve para volver a unir las partes en un solo archivo (Niklas, 2020, p. 83; *Redireccionamiento y Pipes*, p. 3).
- **SSH.** Además de dar acceso remoto, permite copiar datos de forma segura entre equipos (*SSH*, p. 1). Para la copia se usó la misma clave privada configurada en el punto 2.2.
- **Límite de GitHub.** Desde la página web, GitHub no acepta archivos de más de **25 MB**. Por eso hay que dividir `/var`.

## Procedimiento

### Parte A: carpeta de trabajo en la VM

```bash
mkdir /entrega
cd /entrega
```

Se creó una carpeta propia en la raíz, `/entrega`, que no forma parte de ninguno de los directorios a comprimir. Si los archivos se hubieran generado, por ejemplo, dentro de `/root`, el comprimido de `/root` se habría incluido a sí mismo a medida que crecía (*Comandos*, p. 3).

**Figura 1.** Creación de `/entrega`.

![mkdir entrega](Capturas/Captura%2006.01.png)

### Parte B: comprimir cada directorio

```bash
tar czf root.tar.gz /root
tar czf etc.tar.gz /etc
tar czf opt.tar.gz /opt
tar czf www_dir.tar.gz /www_dir
tar czf backup_dir.tar.gz /backup_dir
tar czf var.tar.gz /var
```

Es la misma forma que usa Niklas (2020, p. 62) en su ejemplo de respaldo (`tar czf apache.tar.gz /var/www`). Igual que en el punto 5, el aviso `Eliminando la '/' inicial de los nombres` no es un error. Indica que las rutas se guardan sin la `/` inicial, así que al descomprimir no se pisan los archivos del sistema.

**Figura 2.** Compresión de `/root`.

![tar root](Capturas/Captura%2006.02.png)

**Figura 3.** Los seis directorios comprimidos.

![tar todos](Capturas/Captura%2006.03.png)

### Parte C: dividir `/var`

```bash
split -b 20M var.tar.gz var.tar.gz.part_
```

`var.tar.gz` ocupa 94 MB, más que el límite de 25 MB de GitHub. `split` lo divide en partes de 20 MB:

- `-b 20M` indica el tamaño de cada parte;
- el último argumento es el prefijo de los nombres, al que `split` le agrega `aa`, `ab`, `ac`…

Se eligió 20 MB para quedar por debajo del límite con margen. La opción `-b` no figura en la bibliografía: se consultó en `man split` (*Comandos*, p. 1; Niklas, 2020, p. 60).

**Figura 4.** División de `var.tar.gz`.

![split](Capturas/Captura%2006.04.png)

```bash
ls -lh /entrega
```

**Figura 5.** Contenido de `/entrega`: los seis `.tar.gz` y las cinco partes de `var`.

![ls -lh](Capturas/Captura%2006.05.png)

| Archivo | Tamaño |
|---|---|
| `root.tar.gz` | 368 K |
| `etc.tar.gz` | 661 K |
| `opt.tar.gz` | 1,4 K |
| `www_dir.tar.gz` | 3,0 K |
| `backup_dir.tar.gz` | 7,9 M |
| `var.tar.gz` (completo, no se sube) | 94 M |
| `var.tar.gz.part_aa` a `part_ad` | 20 M cada una |
| `var.tar.gz.part_ae` | 14 M |

### Parte D: copiar los archivos de la VM a Windows

Desde el Símbolo del sistema de Windows, en la carpeta del usuario donde está guardada `clave_privada.txt` (punto 2.2):

```
mkdir TPI_Grupo_02
scp -i clave_privada.txt root@192.168.0.209:/entrega/* TPI_Grupo_02
dir TPI_Grupo_02
```

- `scp` copia archivos a través de SSH. `-i clave_privada.txt` indica la clave privada, igual que al conectarse con `ssh` en el punto 2.2; por eso no pidió contraseña.
- `root@192.168.0.209:/entrega/*` significa "todos los archivos de `/entrega` en la VM, entrando como root". La IP es la estática configurada en el punto 3.
- `TPI_Grupo_02` es la carpeta de destino en Windows.

`scp` no figura como comando en la bibliografía. El apunte *SSH* (p. 1) indica que SSH permite copiar datos de forma segura, y el uso de `scp` se consultó en su manual.

`dir` mostró los **11 archivos**. Al sumar las partes se obtiene exactamente el tamaño del original:

4 × 20.971.520 + 14.456.902 = **98.342.982 bytes** = tamaño de `var.tar.gz`

**Figura 6.** Copia con `scp` y verificación con `dir`.

![scp y dir](Capturas/Captura%2006.06.png)

Como `var.tar.gz` completo no se puede subir, se lo sacó de la carpeta antes de subirla. Así no se incluye por error al arrastrar la carpeta:

```
move TPI_Grupo_02\var.tar.gz
dir TPI_Grupo_02
```

Sin destino, `move` lleva el archivo a la carpeta actual. Quedaron **10 archivos** en `TPI_Grupo_02`.

**Figura 7.** `var.tar.gz` fuera de la carpeta: quedan 10 archivos.

![move](Capturas/Captura%2006.07.png)

**Figura 8.** La carpeta vista desde el Explorador de Windows.

![explorador](Capturas/Captura%2006.08.png)

### Parte E: subida a GitHub

El primer intento fue arrastrar la carpeta entera a **Add file → Upload files**. GitHub respondió **Commit failed: the file is too large**: aunque ningún archivo pasa los 25 MB, subir los ~107 MB en una sola confirmación (*commit*) superó lo que admite la página web.

**Figura 9.** Primer intento rechazado.

![commit fallido](Capturas/Captura%2006.09.png)

La solución fue **subir por tandas**:

1. Con **Add file → Create new file** se escribió como nombre `TPI_Grupo_02/README.md`. Al escribir la `/`, GitHub crea la carpeta. El README explica qué contiene la carpeta y cómo reconstruir `var.tar.gz`.
2. Dentro de esa carpeta, **Add file → Upload files** con los cinco comprimidos chicos juntos (`root`, `etc`, `opt`, `www_dir` y `backup_dir`).
3. Las cinco partes de `var`, **de a una por confirmación** (`part_aa` … `part_ae`).

**Figura 10.** Subida de los cinco comprimidos.

![subida comprimidos](Capturas/Captura%2006.10.png)

**Figura 11.** Subida de la primera parte de `var`.

![parte aa](Capturas/Captura%2006.11.png)

**Figura 12.** Subida de la última parte de `var`.

![parte ae](Capturas/Captura%2006.12.png)

**Figura 13.** La carpeta en el repositorio: README, cinco comprimidos y cinco partes.

![repositorio](Capturas/Captura%2006.13.png)

Después la carpeta se renombró a **`06_Entregables`**, para que siga la numeración de los demás puntos del repositorio, y se agregó este documento junto a los archivos.

### Parte F: cómo reconstruir `/var`

En cualquier equipo Linux, dentro de la carpeta con las cinco partes:

```bash
cat var.tar.gz.part_* > var.tar.gz
tar xvzf var.tar.gz
```

`cat` concatena las partes en orden alfabético (`aa`, `ab`, `ac`…), que es el mismo orden en que `split` las generó. `>` guarda el resultado en un archivo (Niklas, 2020, pp. 62 y 83; *Redireccionamiento y Pipes*, p. 3).

Se comprobó la reconstrucción **fuera de la VM**, a partir de una copia descargada del repositorio. El archivo unido mide 98.342.982 bytes, igual que el original, y se descomprime sin errores. Los otros cinco `.tar.gz` también se comprobaron.

### Parte G: cierre en la VM

```bash
history
shutdown -h now
```

**Figura 14.** `history` con los comandos del punto 6 (líneas 164 a 174).

![history](Capturas/Captura%2006.14.png)

Con la VM apagada se tomó la instantánea **`10 - Punto 6 Entregables`**.

**Figura 15.** Árbol de instantáneas de VirtualBox, del 00 al 10.

![instantáneas](Capturas/Captura%2006.15.png)

## Problemas encontrados y solución

**Límite de tamaño de GitHub web.** `var.tar.gz` (94 MB) no se puede subir entero, así que se dividió con `split -b 20M`. Además, subir todo junto en una sola confirmación también fue rechazado. Se resolvió subiendo por tandas: primero los archivos chicos y después cada parte por separado.

**Evitar subir `var.tar.gz` completo.** `scp` copió también el original de 94 MB. Para no arrastrarlo por error, se movió fuera de la carpeta antes de subirla.

**Datos sensibles dentro de los comprimidos.** La consigna pide comprimir `/root` y `/etc`, y esos directorios contienen la clave privada provista por la cátedra y los archivos de contraseñas de la VM (`/etc/shadow`). Son datos de la máquina de laboratorio, no de los integrantes, y el repositorio es privado. De todos modos, conviene tenerlo presente si alguna vez se lo hace público.

**Datos personales en las capturas.** En las capturas de Windows y del navegador se taparon el nombre de usuario de Windows, el número de serie del disco, el usuario de GitHub y las imágenes de perfil.

## Resultado

- Repositorio en GitHub con `README.md` e integrantes.
- `root.tar.gz`, `etc.tar.gz`, `opt.tar.gz`, `www_dir.tar.gz` y `backup_dir.tar.gz` comprimidos por separado.
- `/var` comprimido y dividido en cinco partes de hasta 20 MB, con instrucciones para reconstruirlo, verificadas.

**Instantánea de VirtualBox:** `10 - Punto 6 Entregables`.

## Referencias bibliográficas

- Niklas, P. (2020). *GNU/Linux, con sabor a Debian* (1.ª ed.).
- Universidad de Palermo. (s. f.). *Comandos* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Redireccionamiento y Pipes* [Material de cátedra].
- Universidad de Palermo. (s. f.). *SSH* [Material de cátedra].
