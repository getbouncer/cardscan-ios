from jinja2 import Template
import sys

def main():
    if len(sys.argv) != 2:
        print('Usage {}: version < CardScan.podspec.template > CardScan.podspec'.format(sys.argv[0]))
        sys.exit(1)

    values = {'version': sys.argv[1]}

    template = Template(sys.stdin.read())
    sys.stdout.write(template.render(values))

    
if __name__ == '__main__':
    main()
