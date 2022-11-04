# somalier_UDD

Guía para realizar análisis de parentesco de un set de muestras (a partir de archivos fastq.gz) utilizando la herramineta somalier. Este flujo de trabajo, necesita como entrada la ruta de una carpeta con archivos fastq.gz (paired-end).


## 1. Instalación ##

* 1) Copiar el repositorio
```
git clone https://github.com/evelingonzalezfeliu/somalier_UDD.git
```
* 2) Descargar binario de somalier
```
wget https://github.com/brentp/somalier/releases/download/v0.2.16/somalier
```
* 3) Agregar directorio de somalier al $PATH
```
export PATH=/output/dir/somalier/donwloaded:$PATH
```
* 4) Instalar bwa
```
sudo apt-get install bwa
```
## 2. Parámetros de entrada ##

Para ejecutar este pipeline es necesario indicarle al programa donde se encuentra los siguintes archivos; el genoma de referencia y los sitios (polimorfismos) utilizados por somalier para calcular la relacion entre muestras. Este último se encuentra en el repositorio ```sites.hg19.vcf.gz```

Se deben modificar las variables ```hg19_fa``` y ```sites_hg19``` que se encuentran al inicio del archivo ```run_somalier.sh```
Ejemplo:
```
hg19_fa="/home/administrador/Documentos/BD_TumorSec/hg19.fa"
sites_hg19="/home/administrador/Documentos/somalier_UDD/sites.hg19.vcf.gz"
```

## 3. Ejecutar workflow ##

En la carpeta copiada del repositorio *(paso 1.1)*, se encuentra el archivo ```run_somalier.sh```, el cual, realizará el análisis de parentesco de manera automática. Para esto, ejecur el script e ingresar los parámetros de entrada solicitados por el programa. Ver el siguiente ejemplo:

```
sh run_somalier.sh

Enter the output directory:
/home/administrador/Documentos/WorkSpace_2022/031122_Test_pipeline_somalier

Enter the FASTQ directory:
/home/administrador/Documentos/WorkSpace_2022/031122_Test_pipeline_somalier/FASTQ

What steps do you want to execute?
1. Mapping
2. Somalier extract
3. Somalier relate
Example, all pipeline -> 1-3, only mapping -> 1, from mapping to Somalier extract -> 1-2
1-3

Threads:
10

############################################
     Welcome to the somalier pipeline
############################################

== Extract informative sites, evaluate relatedness, and perform quality-control  ==

Thu 03 Nov 2022 10:56:58 PM -03 : step 1 - start - mapping
Thu 03 Nov 2022 10:56:58 PM -03 : step 1 - logfile - /home/administrador/Documentos/WorkSpace_2022/031122_Test_pipeline_somalier/0_logs/1_log_mapping.out
```




