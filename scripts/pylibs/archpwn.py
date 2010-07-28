GLOBAL_MAPPINGS = {
    "archpwn-bluetooth":   ('Bluetooth',   'bluetooth'),
    "archpwn-bruteforce":  ('Bruteforce',  'bruteforce'),
    "archpwn-cisco":       ('Cisco',       'cisco'),
    "archpwn-database":    ('Database',    'database'),
    "archpwn-dect":        ('DECT',        'dect'),
    "archpwn-defense":     ('Defense',     'defense'),
    "archpwn-enumeration": ('Enumeration', 'enumeration'),
    "archpwn-exploits":    ('Exploits',    'exploits'),
    "archpwn-forensic":    ('Forensics',   'forensic'),
    "archpwn-fuzzer":      ('Fuzzing',     'fuzzers'),
    "archpwn-misc":        ('Misc',        'misc'),
    "archpwn-password":    ('Password',    'password'),
    "archpwn-reversing":   ('Reversing',   'reversing'),
    "archpwn-scanners":    ('Scanners',    'scanners'),
    "archpwn-smartcard":   ('Smartcards',  'smartcards'),
    "archpwn-sniffer":     ('Sniffing',    'sniffers'),
    "archpwn-spoofing":    ('Spoofing',    'spoofing'),
    "archpwn-tunneling":   ('Tunneling',   'tunneling'),
    "archpwn-voip":        ('VoIP',        'voip'),
    "archpwn-windows":     ('Windows',     'windows'),
    "archpwn-wireless":    ('Wireless',    'wireless'),
    "archpwn-www":         ('WWW',         'www'),
}

def get_category(group):
    return GLOBAL_MAPPINGS[group][0]

def iget_categories(groups):
    for group in groups:
        yield get_category(group)

def get_categories(groups):
    return [x for x in iget_categories(groups)]

def get_directory(group):
    return GLOBAL_MAPPINGS[group][1]

def iget_directories(groups):
    for group in groups:
        yield get_directory(group)

def get_directories(groups):
    return [x for x in iget_directories(groups)]
