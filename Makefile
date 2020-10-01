re2c = re2c
re2c_flags = -W -Werror --no-generation-date

zone.c: zone.re
	${re2c} ${re2c_flags} zone.re >zone.c

zone.re: zone2re.pl zone2c.re db.zone
	./zone2re.pl db.zone >zone.re
