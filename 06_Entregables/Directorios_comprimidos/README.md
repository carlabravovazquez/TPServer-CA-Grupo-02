# Directorios comprimidos

/root, /etc, /opt, /www_dir y /backup_dir comprimidos individualmente con tar czf.

/var comprimido y dividido con split -b 20M en 5 partes (part_aa a part_ae).
Para reconstruirlo: cat var.tar.gz.part_* > var.tar.gz
