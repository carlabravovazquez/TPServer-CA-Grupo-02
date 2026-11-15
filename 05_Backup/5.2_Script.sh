#!/bin/bash
#
# ====================================================================================================
#
# Integrantes:
#
#             - Bravo-Vazquez, Carla Sofía del Rosario
#             - Figueredo, Rodrigo Alejandro
#             - Guitar, Ramiro
#             - Luna Ferenaz, Julián
#             - Quercia Acosta, Mario
#             - Zattera, María Paula
#
# ====================================================================================================
#
# Script: backup_full.sh
#
# Ubicación: /opt/scripts/backup_full.sh
#
# Descripción: Comprime un directorio de origen en un archivo .tar.gz dentro del directorio destino.
#
# Nombre del backup: NOMBRE_bkp_AAAAMMDD.tar.gz
#
# Uso: backup_full.sh ORIGEN DESTINO
#
# Códigos de salida:
#                    - 0 OK
#                    - 1 argumentos
#                    - 2 origen
#                    - 3 destino
#                    - 4 no montado
#                    - 5 error tar
#
# ====================================================================================================
#
# Opción de ayuda (-help)
#
# ====================================================================================================
#
# $1 es el primer argumento (si es -help muestra la ayuda)
#
if [ "$1" = "-help" ]
then
    echo "Uso: $0 ORIGEN DESTINO"
    echo "Comprime ORIGEN en DESTINO/nombre_bkp_AAAAMMDD.tar.gz"
    echo "Ejemplo: $0 /var/log /backup_dir"
    exit 0
fi
#
# ====================================================================================================
#
# Validación de la cantidad de argumentos
#
# ====================================================================================================
#
# $# es la cantidad de argumentos (tienen que ser 2)
#
if [ $# -ne 2  ]
then
    echo "Error: se necesitan 2 argumentos. Ver: $0 - help"
    exit 1
fi
#
# Guardamos los argumentos en variables
#
ORIGEN=$1
DESTINO=$2
#
# ====================================================================================================
#
# Validación del origen
#
# ====================================================================================================
#
# -d comprueba que el origen exista y sea un directorio
#
[ -d $ORIGEN ]
if [ $? -ne 0 ]
then
    echo "Error: el origen $ORIGEN no existe"
    exit 2
fi
#
#
# Si el origen tiene un partición propia en /etc/fstab tiene que estar montada.
#
grep $ORIGEN /etc/fstab > /dev/null
if [ $? -eq 0 ]
then
    df -h | grep $ORIGEN > /dev/null
    if [ $? -ne 0 ]
    then
       echo "Error: $ORIGEN no está montado"
       exit 2
    fi
fi
#
# ====================================================================================================
#
# Validación del destino
#
# ====================================================================================================
#
# -d comprueba que el destino exista y sea un directorio
#
[ -d $DESTINO ]
if [ $? -ne 0 ]
then
    echo "Error: el destino $DESTINO no existe"
    exit 3
fi
#
#
# df -h lista lo montado y grep busca el destino.
#
df -h | grep $DESTINO > /dev/null
if [ $? -ne 0 ]
then
    echo "Error: $DESTINO no está montado"
    exit 4
fi
#
# ====================================================================================================
#
# Creación del backup
#
# ====================================================================================================
#
# Nombre: destino + nombre del origen + _bkp_ + fecha AAAAMMDD
# tar c (crea), z (comprime con gzip), f (indica el archivo)
#
ARCHIVO=$DESTINO/`basename $ORIGEN`_bkp_`date +%Y%m%d`.tar.gz
tar czf $ARCHIVO $ORIGEN
#
# ====================================================================================================
#
# Verificación del resultado
#
# ====================================================================================================
#
# $? guarda el resultado de tar (0 = salió todo bien)
#
if [ $? -eq 0 ]
then
    echo "Backup Ok: $ARCHIVO"
else
    echo "Error al crear $ARCHIVO"
    exit 5
fi
#
# ====================================================================================================
