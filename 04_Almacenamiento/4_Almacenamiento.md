# 4. Almacenamiento: disco nuevo, particiones y montaje automático

## Objetivo

Según la consigna:

1. agregar a la máquina virtual un disco de **10 GB**;
2. crear dos particiones Linux primarias: **3 GB** montada en **`/www_dir`** y **6 GB** montada en **`/backup_dir`**;
3. que se monten automáticamente al iniciar el sistema;
4. que Apache publique la página desde `/www_dir`;
5. guardar la salida de `/proc/partitions` en el archivo `/opt/particion`.

## Conceptos previos

- **Disco, partición y sistema de archivos.** Un disco se divide en **particiones**; para guardar archivos, cada partición necesita un **sistema de archivos** (formato). Linux nombra los discos `sda`, `sdb`, `sdc`… y sus particiones `sdc1`, `sdc2`… (Universidad de Palermo, s. f., *Introducción a filesystem*, pp. 1–2; *Incorporación de discos*, p. 1).
- **MBR (DOS):** tabla de particiones que admite hasta 4 particiones **primarias** (o 3 primarias y una extendida). Tipo **83** = Linux (*Incorporación de discos*, pp. 2–4).
- **ext4:** sistema de archivos de Linux con **journaling** (registro de cambios que permite recuperarse de un corte) (*Introducción a filesystem*, pp. 1–2).
- **Montaje:** en Linux, una partición se usa "colgándola" de un directorio (punto de montaje). Lo que se guarda en ese directorio queda en la partición (*Incorporación de discos*, pp. 5–6).
- **`/etc/fstab`:** archivo que lista qué se monta automáticamente al iniciar (*Incorporación de discos*, pp. 7–8).
- **`/proc`:** sistema de archivos **virtual**: lo genera el kernel en memoria y muestra información del sistema; `/proc/partitions` lista los discos y particiones que detecta. **`/opt`** está destinado a software y datos adicionales (*El standard FHS*, p. 3).

## Procedimiento

### Parte A: agregar el disco en VirtualBox

El disco se agrega con la VM **apagada** (*Introducción a filesystem*, pp. 3–6; actividad *Agregando discos*, pp. 1–3).

| # | Acción |
|---|---|
| 1 | Clic derecho sobre `TPVMCA` → **Configuración** → **Almacenamiento** |
| 2 | Seleccionar **Controlador: SATA** → ícono de disco con **+** (agregar disco duro) |
| 3 | En el selector, **Crear** |
| 4 | Nombre `TPVMCA_disco_10GB`, tamaño **10 GB**, tipo **VDI**, **sin** tildar "Reservar completamente" (disco dinámico: ocupa espacio real a medida que se usa) → **Terminar** |
| 5 | Seleccionar el disco nuevo → **Elegir** → **Aceptar** |

**Figura 1.** Configuración de almacenamiento de la VM.

![almacenamiento](Capturas/Captura%2004.01.png)

**Figura 2.** Opción para agregar un disco.

![menú](Capturas/Captura%2004.02.png)

**Figura 3.** Selector de discos.

![selector](Capturas/Captura%2004.03.png)

**Figura 4.** Creación del disco virtual.

![crear](Capturas/Captura%2004.04.png)

**Figura 5.** Disco de 10 GB, formato VDI, sin reservar completamente.

![10 GB](Capturas/Captura%2004.05.png)

**Figura 6.** Disco nuevo en el selector.

![seleccionado](Capturas/Captura%2004.06.png)

**Figura 7.** La VM con tres discos.

![tres discos](Capturas/Captura%2004.07.png)

### Parte B: particiones y sistema de archivos

```bash
lsblk
```

`lsblk` lista los dispositivos de bloque (discos y particiones) (*Incorporación de discos*, p. 1; actividad *Agregando discos*, p. 3). Aparece un disco nuevo de 10G sin particiones: **`sdc`**. No es `sdb` porque la VM de la cátedra ya trae un segundo disco (`sdb`, con la partición `sdb1` montada en `/home`). **Confirmar el nombre con `lsblk` es indispensable:** particionar el disco equivocado borraría datos (actividad *Agregando discos*, p. 7).

**Figura 8.** Disco nuevo detectado como `sdc`.

![lsblk](Capturas/Captura%2004.08.png)

```bash
fdisk /dev/sdc
```

`fdisk` administra la tabla de particiones de un disco. Los cambios quedan en memoria hasta que se escriben con `w` (*Incorporación de discos*, pp. 2–4; actividad *Agregando discos*, p. 4). Como el disco está vacío, `fdisk` crea una etiqueta **DOS (MBR)**.

Cada respuesta se escribe después de la pregunta y se confirma con **Enter**:

| Pregunta de `fdisk` | Respuesta | Significado |
|---|---|---|
| `Orden (m para obtener ayuda):` | `n` | *new*: partición nueva |
| `Seleccionar (valor predeterminado p):` | `p` | primaria |
| `Número de partición (1-4, valor predeterminado 1):` | `1` | partición 1 |
| `Primer sector (2048-20971519, valor predeterminado 2048):` | Enter | acepta el inicio sugerido |
| `Último sector, +/-sectores o +/-tamaño{K,M,G,T,P}` | `+3G` | tamaño de 3 GB (`G` en mayúscula) |
| `Orden:` | `n` → `p` → `2` → Enter → `+6G` | partición 2 de 6 GB |
| `Orden:` | `p` | *print*: muestra la tabla antes de guardar |
| `Orden:` | `w` | *write*: escribe la tabla en el disco y sale |

Si algo sale mal antes de `w`, `q` sale sin guardar.

**Figura 9.** Inicio de `fdisk`.

![fdisk inicio](Capturas/Captura%2004.09.png)

**Figura 10.** Partición 1 (3 GB).

![partición 1](Capturas/Captura%2004.10.png)

**Figura 11.** Partición 2 (6 GB).

![partición 2](Capturas/Captura%2004.11.png)

La tabla (`p`) muestra `/dev/sdc1` de **3G** y `/dev/sdc2` de **6G**, ambas con **Id 83, tipo Linux**, que es lo que pide la consigna.

**Figura 12.** Tabla de particiones antes de escribirla.

![tabla](Capturas/Captura%2004.12.png)

Después de `w`, `fdisk` informa *"Se ha modificado la tabla de particiones"* y `lsblk` ya muestra `sdc1` (3G) y `sdc2` (6G).

**Figura 13.** Tabla escrita y particiones visibles.

![w lsblk](Capturas/Captura%2004.13.png)

```bash
mkfs -t ext4 /dev/sdc1
mkfs -t ext4 /dev/sdc2
```

`mkfs` crea el sistema de archivos; `-t ext4` indica el tipo (*Incorporación de discos*, p. 5; actividad *Agregando discos*, pp. 4–5). La salida muestra el identificador único (**UUID**), las copias de respaldo del superbloque y `Creating journal … done` (el journal de ext4).

**Figura 14.** Formato de `sdc1`.

![mkfs sdc1](Capturas/Captura%2004.14.png)

**Figura 15.** Formato de `sdc2`, con el error de opción del primer intento (ver problema 1).

![mkfs sdc2](Capturas/Captura%2004.15.png)

```bash
mkdir /www_dir /backup_dir
mount /dev/sdc1 /www_dir
mount /dev/sdc2 /backup_dir
df -h
```

`mkdir` crea los dos puntos de montaje en un solo comando; `mount dispositivo directorio` monta cada partición, y `df -h` muestra los sistemas de archivos montados con tamaños legibles (`-h` = *human*) (*Incorporación de discos*, pp. 5–6; actividad *Agregando discos*, p. 5). `df -h` muestra `/dev/sdc1` (2,9G) en `/www_dir` y `/dev/sdc2` (5,9G) en `/backup_dir`.

**Figura 16.** Particiones montadas en forma manual.

![mount df](Capturas/Captura%2004.16.png)

### Parte C: montaje automático con `/etc/fstab`

```bash
cp /etc/fstab /etc/fstab.orig
cat /etc/fstab
vi /etc/fstab
```

En `vi`: `G` (última línea) → `o` (línea nueva debajo, modo inserción) → se escriben las dos líneas → **Esc** → `:wq` + Enter.

```text
/dev/sdc1 /www_dir ext4 defaults 0 2
/dev/sdc2 /backup_dir ext4 defaults 0 2
```

Campos de cada línea (*Incorporación de discos*, pp. 7–8; actividad *Agregando discos*, p. 5):

| Campo | Valor | Significado |
|---|---|---|
| 1. Sistema de archivos | `/dev/sdc1` | Partición a montar (el apunte admite la ruta o el UUID) |
| 2. Punto de montaje | `/www_dir` | Directorio donde se monta |
| 3. Tipo | `ext4` | Sistema de archivos |
| 4. Opciones | `defaults` | Opciones estándar (lectura/escritura, montaje automático, etc.) |
| 5. Dump | `0` | No se respalda con la herramienta `dump` |
| 6. Pass | `2` | Orden de revisión con `fsck` al iniciar: `1` es la raíz, `2` las demás |

Las líneas que ya estaban (la raíz por UUID, la swap, el CD y la línea 13, `/dev/sdb1 /home ext4 rw,auto 0 0`, de la cátedra) no se tocaron.

**Figura 17.** Las dos líneas nuevas (14 y 15) escritas en `vi`.

![fstab en vi](Capturas/Captura%2004.17.png)

```bash
cat /etc/fstab
umount /www_dir /backup_dir
df -h
mount -a
df -h
```

`vi` confirmó `"/etc/fstab" 15L, 779B escritos`.

**Figura 18.** `vi` confirma el guardado y `cat` muestra el archivo completo.

![cat fstab](Capturas/Captura%2004.18.png)

 Para comprobar el `fstab` **sin reiniciar**: se desmontaron las dos particiones con `umount` (desaparecen de `df -h`) y se ejecutó **`mount -a`**, que monta todo lo que figura en `fstab` y todavía no está montado (actividad *Agregando discos*, p. 6). Si `fstab` tuviera un error, `mount -a` lo mostraría en ese momento y no al reiniciar.

**Figura 19.** `umount` y `mount -a` (con el aviso de `systemd`, ver problema 2).

![umount mount -a](Capturas/Captura%2004.19.png)

### Parte D: Apache sirviendo desde `/www_dir`

```bash
cp /root/Material_Adicional_TPVMCA/index.php /root/Material_Adicional_TPVMCA/logo.png /www_dir/
ls -l /www_dir/
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
```

En `/www_dir` quedan `index.php`, `logo.png` y `lost+found` (carpeta que crea `mkfs` en cada sistema de archivos ext4 para recuperar archivos después de una revisión) (*Comandos*, p. 2).

**Cambio 1: `DocumentRoot`.** El sitio por defecto se define en `000-default.conf` (*El standard FHS*, p. 2; Niklas, 2020, p. 254). La directiva `DocumentRoot` indica qué carpeta publica Apache.

```bash
vi /etc/apache2/sites-available/000-default.conf
```

En `vi`: `/DocumentRoot` + Enter → se reemplaza la ruta `/var/www/html` por `/www_dir` → **Esc** → `:wq`. La línea 12 quedó:

```text
DocumentRoot /www_dir
```

**Figura 20.** `DocumentRoot` apuntando a la partición.

![DocumentRoot](Capturas/Captura%2004.20.png)

**Cambio 2: permiso de acceso al directorio.** `apache2.conf` niega por defecto el acceso a todo el sistema de archivos (`<Directory />` … `Require all denied`) y solo lo habilita para `/usr/share` y `/var/www`. Sin un permiso para `/www_dir`, Apache respondería **403 Forbidden**.

```bash
grep -n "Directory /var/www" /etc/apache2/apache2.conf
vi /etc/apache2/apache2.conf
```

`grep -n` muestra el número de línea donde está el bloque de `/var/www` (*Streams y filtros*, p. 3). En `vi`: `:170` + Enter (va a la línea 170, después de ese bloque) → `o` → se escribe el bloque → **Esc** → `:wq`.

```text
<Directory /www_dir/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```

| Directiva | Qué hace |
|---|---|
| `<Directory /www_dir/>` … `</Directory>` | Las reglas se aplican a esa carpeta |
| `Options Indexes FollowSymLinks` | Si no hay página de inicio, muestra la lista de archivos; permite seguir enlaces simbólicos |
| `AllowOverride None` | No admite archivos `.htaccess` que cambien la configuración |
| `Require all granted` | Permite el acceso a todos los visitantes |

Es el mismo bloque que Debian trae para `/var/www`, con la ruta cambiada. Estas directivas no están en la bibliografía; la consigna nombra los archivos que hay que modificar.

**Figura 21.** Bloque `<Directory /www_dir/>` en las líneas 170–174.

![apache2.conf](Capturas/Captura%2004.21.png)

```bash
grep DocumentRoot /etc/apache2/sites-available/000-default.conf
grep "Directory /www_dir" /etc/apache2/apache2.conf
systemctl restart apache2
systemctl status apache2
```

Las comillas en el segundo `grep` hacen que `Directory /www_dir` se busque como un solo texto, con el espacio incluido. Apache se reinició sin errores: `active (running)` (*Init y Systemd*, p. 4).

**Figura 22.** Desde Windows, la tabla de alumnos servida desde `/www_dir`.

![web www_dir](Capturas/Captura%2004.22.png)

### Prueba de que la página sale de la partición

| Paso | Comando o acción | Resultado |
|---|---|---|
| 1 | `umount /www_dir` · `ls -l /www_dir` | `total 0`: sin la partición, la carpeta está vacía (los archivos están en `sdc1`, no en el disco del sistema) |
| 2 | Navegador → **F5** | **"Index of /"** vacío: Apache lista una carpeta sin archivos (por `Options Indexes`) |
| 3 | `mount -a` · `ls -l /www_dir` | Vuelven `index.php`, `logo.png` y `lost+found` |
| 4 | Navegador → **F5** | La tabla de alumnos aparece otra vez |

**Figura 23.** "Index of /" con la partición desmontada.

![Index of](Capturas/Captura%2004.23.png)

**Figura 24.** Verificación de la configuración, reinicio de Apache, desmontaje y nuevo montaje.

![remontaje](Capturas/Captura%2004.24.png)

**Figura 25.** Página completa después de volver a montar.

![final](Capturas/Captura%2004.25.png)

### Parte E: `/proc/partitions` en `/opt/particion` y reinicio

```bash
cat /proc/partitions
cat /proc/partitions > /opt/particion
ls -l /opt
cat /opt/particion
```

`/proc/partitions` lista cada dispositivo con su número mayor y menor, su tamaño en bloques de 1 KB y su nombre: `sdc` 10485760 (10 GB), **`sdc1` 3145728 (3 GB)** y **`sdc2` 6291456 (6 GB)**. El símbolo **`>`** guarda esa salida en `/opt/particion` (si existiera, lo reemplazaría) (*Redireccionamiento y Pipes*, p. 1; *El standard FHS*, p. 3). El archivo creado ocupa 295 bytes.

**Figura 26.** Contenido de `/proc/partitions` y creación de `/opt/particion`.

![proc partitions](Capturas/Captura%2004.26.png)

**Figura 27.** Contenido de `/opt/particion` y reinicio.

![cat particion](Capturas/Captura%2004.27.png)

```bash
shutdown -r now
```

Después de iniciar sesión otra vez:

```bash
df -h
cat /opt/particion
```

`df -h` muestra **`/dev/sdc1 2,9G … /www_dir`** y **`/dev/sdc2 5,9G … /backup_dir`**, montadas automáticamente por `fstab`. (Aparecen 2,9 y 5,9 GB porque el sistema de archivos reserva una parte del espacio para su propia estructura.) `/opt/particion` sigue existiendo: a diferencia de `/proc`, está guardado en el disco.

**Figura 28.** Montaje automático después del reinicio.

![df -h](Capturas/Captura%2004.28.png)

```bash
history
shutdown -h now
```

**Figura 29.** `history` del punto 4 (líneas 92–136).

![history](Capturas/Captura%2004.29.png)

Orden real: `lsblk` → `fdisk /dev/sdc` → `lsblk` → `mkfs -t ext4 /dev/sdc1` → `mkfs -f ext4 /dev/sdc2` (error) → `mkfs -t ext4 /dev/sdc2` → `mkdir` → `mount` ×2 → `df -h` → `cp /etc/fstab /etc/fstab.orig` → `cat` → `vi /etc/fstab` → `cat` → `umount` → `df -h` → `mount -a` → `df -h` → `systemctl daemon-reload` → `cp index.php logo.png /www_dir/` → `ls -l` → respaldos `.orig` → `vi 000-default.conf` → `grep -n` → `vi apache2.conf` (salida con `:q!`) → `ls -l apache2.conf*` → `grep -n` → `vi apache2.conf` → `grep` ×2 → `systemctl restart apache2` · `systemctl status apache2` → `umount /www_dir` → `ls` → `mount -a` → `ls` → `cat /proc/partitions` → `cat /proc/partitions > /opt/particion` → `ls -l /opt` → `cat /opt/particion` → `shutdown -r now` → `df -h` → `cat /opt/particion` → `history`.

## Problemas encontrados y solución

Al formatear la segunda partición se escribió `mkfs -f ext4 /dev/sdc2` en lugar de `-t`, y el sistema respondió `opción inválida -- 'f'`. Como el comando no llegó a ejecutarse, no se modificó nada; se repitió con la opción correcta.

Después de editar `/etc/fstab` y ejecutar `mount -a`, el sistema mostró el aviso *"your fstab has been modified, but systemd still uses the old version; use 'systemctl daemon-reload' to reload"*. `systemd` arma sus unidades de montaje a partir de `fstab` y todavía tenía en memoria la versión anterior. El montaje se había hecho igual, pero se ejecutó `systemctl daemon-reload`, como sugería el propio mensaje. El comando `systemctl` está en el apunte *Init y Systemd* (p. 4), aunque la opción `daemon-reload` no figura en la bibliografía: se usó porque la indicó el sistema.

Mientras se editaba `apache2.conf`, pareció que se había borrado parte del texto. Para no arriesgar el archivo, se salió **sin guardar** con **Esc** y `:q!`. Se comprobó que el archivo seguía intacto (`225L, 7178B`, igual que la copia de respaldo), se volvió a abrir y se fue directamente a la línea correcta con `:170`.

Por último, en VirtualBox la opción "Configuración" aparecía deshabilitada porque estaba seleccionada una instantánea en lugar del estado actual de la máquina. Se resolvió seleccionando "Estado actual" o usando el clic derecho sobre la máquina virtual.

## Resultado

- Disco de 10 GB (`sdc`) con dos particiones primarias ext4: `sdc1` (3 GB) en `/www_dir` y `sdc2` (6 GB) en `/backup_dir`.
- Montaje automático por `/etc/fstab`, comprobado con `mount -a` y con un reinicio.
- Apache publica la página desde `/www_dir`, comprobado desmontando y volviendo a montar la partición.
- `/opt/particion` contiene la salida de `/proc/partitions`.

**Instantánea de VirtualBox:** `08 - Punto 4 Almacenamiento` (VM apagada con `shutdown -h now`, por lo que el historial quedó guardado).

## Referencias bibliográficas

- Niklas, P. (2020). *GNU/Linux, con sabor a Debian* (1.ª ed.).
- Universidad de Palermo. (s. f.). *Agregando discos* [Actividad de cátedra].
- Universidad de Palermo. (s. f.). *Comandos* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Editores de texto* [Material de cátedra].
- Universidad de Palermo. (s. f.). *El standard FHS* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Incorporación de discos* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Init y Systemd* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Introducción a filesystem* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Redireccionamiento y Pipes* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Streams y filtros* [Material de cátedra].
