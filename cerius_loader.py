import subprocess
import os

class Loader( object ):
    def __init__( self ):
        self.listFile = 'list'
        self.template = 'matt'

        self.part1 = """_GUI/MODAL 1
_SYSTEM/REINIT_ALL
FILES/LOAD_FORMAT  PDB
VIEW/OVERLAY
EDIT/INHIBIT_S_BONDS  NO
FILES/PDB_LOAD_TYPE  CHARMm/X-PLOR""".strip()

        self.part2 = """MODEL/SET_VISIBLE
VIEW/RESET_VIEW
MODEL/SET_INVISIBLE
""".strip()

    def getpwd( self ):
        pwd = subprocess.check_output('pwd', universal_newlines=True)

        return pwd.strip()

    def getfiles( self ):
        with open(self.listFile, 'r') as listFile:
            self.files = listFile.readlines()

        return self.files

    def make( self ):
        finalStr = ''

        finalStr += self.part1 + '\n'

        for file in self.getfiles():
            pwd = self.getpwd() + '/'
            finalStr += 'FILES/LOAD  ' + '"' + pwd + file.strip() + '-out.pdb' + '"' + '\n'
        finalStr += self.part2 + '\n'

        return finalStr
        
    def write( self ):
        with open('res', 'w') as resFile:
            resFile.write(self.make())

if __name__ == '__main__':
    Load = Loader()
    Load.write()
    os.system('cat res')
