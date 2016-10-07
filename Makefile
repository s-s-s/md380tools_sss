
RELEASE=md380tools-`date "+%Y-%m-%d"`

#This strips out all unicode characters.
#We'd rather just drop the accents.
ICONV=iconv -c -f UTF-8 -t ascii//TRANSLIT

all: applets
	
clean:
	$(MAKE) -C patches/2.032 clean
	$(MAKE) -C patches/3.020 clean
	$(MAKE) -C patches/s13.020 clean
	$(MAKE) -C patches/d13.020 clean
	$(MAKE) -C firmware clean
	$(MAKE) -C applet clean
	$(MAKE) -C db clean
	rm -f *~ *.pyc
	rm -f data data.csv	

patches: firmwares
	cd patches/2.032 && $(MAKE) all
	cd patches/d13.020 && $(MAKE) all

applets: patches
	cd applet && $(MAKE) all

firmwares:
	$(MAKE) -C firmware all

flash:
	cd applet && $(MAKE) clean flash
	
image_D02:
	$(MAKE) -C applet FW=D02_032 all  

image_D13:
	$(MAKE) -C applet FW=D13_020 all  
	
image_S13:
	$(MAKE) -C applet FW=S13_020 all  
	
flash_d02.032:
	cd applet && $(MAKE) FW=D02_032 clean flash
	
flash_s13.020:
	cd applet && $(MAKE) FW=S13_020 clean flash
	
data:
	$(MAKE) -C db 
	$(ICONV) db/users.csv | cut -d',' -f1-3,5-6 | sed 's/,\s+/,/g' > data.csv
	wc -c < data.csv > data
	cat data.csv >> data
	
flashdb: data
	./md380-tool spiflashwrite data 0x100000

dist: applets
	rm -rf $(RELEASE) $(RELEASE).zip
	mkdir -p $(RELEASE)/python
#Main release.
	$(MAKE) clean image_D13
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-NoGPS"`.bin
#For GPS radios.
	$(MAKE) clean image_S13
#	cd applet && $(MAKE) -f Makefile.s13.020 clean all
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-GPS"`.bin
#Older
	$(MAKE) clean image_D02
#	cd applet && $(MAKE) -f Makefile.d02.032 clean all
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-OLD"`.bin
#Include the Official Installer
	cd $(RELEASE) && unzip ../firmware/dl/D002.032.zip
	mv $(RELEASE)/Firmware\ 2.32 $(RELEASE)/windows
	rm $(RELEASE)/windows/MD-380-D2.32\(AD\).bin $(RELEASE)/windows/Operation.doc.pdf
	cp *.py 99-md380.rules md380-dfu md380-tool $(RELEASE)/python/
#Clean out some gunk
	rm -rf $(RELEASE)/__MACOSX
#Zip it up for distribution.
	zip -r $(RELEASE).zip $(RELEASE)

doflash: applets
	./md380-dfu upgrade applet/experiment.bin

all_images:
	$(MAKE) -C applet ci

ci: clean
	$(MAKE) -C applet ci
	$(MAKE) -C db ci
	$(MAKE) data

	