from numpy.core.defchararray import count
from rms import *
from numpy import *
import sys, re, os
from read_write_pdb import *
import argparse
from read_gout import *
import json
import re


def getvalue(s):
    #return the first number in the string s
    nums = list(map(str,range(10)))
    nums.append('-')
    ls = s.split()
    for x in ls:
        if x[0] in nums:
            return x
    return 'none'

def getvalues(s,n):
    #get the first n positive values in the string s
    i = 0
    values = []
    ls = s.split()
    num = list(map(str,range(0,10)))
    for x in ls:
        if i>=n:
            break
        elif x[0] in num:
            values.append(float(x))
            i += 1
    if len(values)==1:
        return values[0]
    else:
        return values


summary={}
summary["directory"]=os.getcwd()
with open("1.out",'r') as fo:
    lines = fo.readlines()
    optend = []
    scf = []
    for l in lines:
        if 'Stationary point found' in l:
            optend.append(l)
        elif l.lstrip().startswith('SCF Done'):
            scf.append(l)
    if bool(optend):
        energy = getvalue(scf[-1])
        initialenergy=getvalue(scf[0])
        summary["ScfEnergy"]=energy
        summary["InitialScfEnergy"]=initialenergy
    else:
        # print('\'<_\' Warning: %s Not Optimized!' % fl)
        print('NA')

DOF = 'Deg. of freedom'
NAtoms = 'NAtoms='
AMU = 'Molecular mass:'
T_CALC = 'Temperature'
ZPVE = 'Zero-point vibrational energy'
THERMAL = 'E (Thermal)'
FREQ = 'Frequencies'


with open("1.out",'r') as fo:
    lines = fo.readlines()
    frequencies=[]
    Atomic_Atomic_Spin_Densities=[]
    exe19999=[]
    firstl999=[]
    secondl9999=[]
    total_steps=0
    ifreq,dof = 0,'?'
    try:
        for i in range(len(lines)):
            line = lines[i].lstrip()
            if line[:len(DOF)]==DOF:
                dof = getvalues(line,1)
                summary["dof"]=int(dof)
            elif line[:len(NAtoms)]==NAtoms:
                natoms = getvalues(line,1)
                summary["natoms"]=int(natoms)
            elif line[:len(AMU)]==AMU:
                amu = getvalues(line,1)
                summary["amu"]=amu
            elif line[:len("radii")]=="radii":
                summary["radii"]=line.split("radii=")[1].replace('\n ','').strip()
            elif line[:len("alpha=")]=="alpha=":
                summary["alpha"]=line.split("alpha=")[1].replace('\n ','').strip()
            elif line[:len("eps=")]=="eps=":
                summary["eps"]=line.split("eps=")[1].replace('\n ','').strip()
            elif line[:len('%chk')]=='%chk':
                summary['CheckPontFile']=line.split("%chk=")[1].strip()
                summary['nprocshared']=str(lines[i+1]).split("nprocshared=")[1].strip()
                summary['memory']=(lines[i+3]).split("%mem=")[1][0:-3].strip()
            elif line[:len(T_CALC)]==T_CALC: 
                #Temperature(Kelvin),Pressure(atm):
                t,p = getvalues(line,2)
                summary["t"]=t
                summary["p"]=p
            elif line[:len(ZPVE)]==ZPVE:
                #ZPVE(Joules/Mol)
                zpve = getvalues(line,1)
                summary["zpve"]=zpve
            elif line[:len(THERMAL)]==THERMAL:
                #S(Cal/Mol-Kelvin)
                S_elec = getvalues(lines[i+3],3)[-1]
                S_trans = getvalues(lines[i+4],3)[-1]
                S_rot = getvalues(lines[i+5],3)[-1]
                summary["S_elec"]=S_elec
                summary["S_trans"]=S_trans
                summary["S_rot"]=S_rot
            elif line[:len("Zero-point correction")]=="Zero-point correction":
                Zero_point_correction=getvalue(line)
                summary["Zero_point_correction"]=Zero_point_correction
            elif line[:len("Thermal correction to Energy")]=="Thermal correction to Energy":
                Thermal_correction_to_Energy=getvalue(line)
                summary["Thermal_correction_to_Energy"]=Thermal_correction_to_Energy
            elif line[:len("Thermal correction to Enthalpy")]=="Thermal correction to Enthalpy":
                Thermal_correction_to_Enthalpy=getvalue(line)
                summary["Thermal_correction_to_Enthalpy"]=Thermal_correction_to_Enthalpy
            elif line[:len("Thermal correction to Gibbs Free Energy")]=="Thermal correction to Gibbs Free Energy":
                Thermal_correction_to_Gibbs_Free_Energy=getvalue(line)
                summary["Thermal_correction_to_Gibbs_Free_Energy"]=Thermal_correction_to_Gibbs_Free_Energy
            elif line[:len("Sum of electronic and zero-point Energies")]=="Sum of electronic and zero-point Energies":
                Sum_of_electronic_and_zero_point_Energies=getvalue(line)
                summary["Sum_of_electronic_and_zero-point_Energies"]=Sum_of_electronic_and_zero_point_Energies
            elif line[:len("Sum of electronic and thermal Energies")]=="Sum of electronic and thermal Energies":
                Sum_of_electronic_and_thermal_Energies=getvalue(line)
                summary["Sum_of_electronic_and_thermal_Energies"]=Sum_of_electronic_and_thermal_Energies
            elif line[:len("Sum of electronic and thermal Enthalpies")]=="Sum of electronic and thermal Enthalpies":
                Sum_of_electronic_and_thermal_Enthalpies=getvalue(line)
                summary["Sum_of_electronic_and_thermal_Enthalpies"]=Sum_of_electronic_and_thermal_Enthalpies
            elif line[:len("Sum of electronic and thermal Free Energies")]=="Sum of electronic and thermal Free Energies":
                Sum_of_electronic_and_thermal_Free_Energies=getvalue(line)
                summary["Sum_of_electronic_and_thermal_Free_Energies"]=Sum_of_electronic_and_thermal_Free_Energies
            elif line[:len(FREQ)]==FREQ:
                #freq(cm^-1)
                ifreq += 1
                freq3 = getvalues(line,3)
                if ifreq==1 and len(freq3)!=3:
                    print("frequency has negative value")
                frequencies.extend(freq3)
            elif "out of a maximum of" in line:
                total_steps=total_steps+1
            elif "nuclear repulsion energy" in line:
                summary["nuclear_repulsion_energy"]=(getvalue(line))
            elif "R6Disp:  Grimme-D3(BJ) Dispersion energy" in line:
                summary["GD3BJ_Dispersion_energy"]=(getvalue(line))
            elif "Largest concise Abelian subgroup " in line:
                summary["Largest_concise_Abelian_subgroup"]=(line.split(" ")[4])
            
            elif "primitive gaussians" in line:
                summary["cartesian_basis_functions"]=int(getvalues(lines[i],3)[-1])
                summary["primitive_gaussians"]=int(getvalues(lines[i],3)[-2])
                summary["beta_electrons"]=int(getvalues(lines[i+1],3)[-1])
                summary["alpha_electrons"]=int(getvalues(lines[i+1],3)[-2])
            elif "Atomic-Atomic Spin Densities." in line:
                Atomic_Atomic_Spin_Densities.append(i)
            elif "l9999.exe)" in line:
                
                if len(lines[i+1])>65 :
                    exe19999.append(i)
            if len(exe19999)>1:
                for i in exe19999:                
                    for line in lines[exe19999[0]:]:                   
                        if len(line.strip())>0:
                            firstl999.append(line)
                            if "    " in line:
                                exe19999.pop()
                                break
            if len(exe19999)>0:
                for i in exe19999:                
                    for line in lines[exe19999[0]:]:                   
                        if len(line.strip())>0:
                            secondl9999.append((line.strip()))
                            
                            if "PG=" in line:
                                exe19999.pop()
                                break
        summary["total_steps"]=total_steps                           
        secondl9999=(''.join(secondl9999))
        firstl999split=secondl9999.split("(Enter /public/apps/gaussian/g16/l9999.exe)")[1].split("\\")
        summary["username"]=(firstl999split[7])
        summary["chemicalformula"]=(firstl999split[6])
        routeline1=(firstl999split[11])        
        summary["routeline1"]=routeline1.replace(",",";")
        summary["commentline1"]=(firstl999split[13].replace(",",";"))
        # print(routeline1.split())
        
                
        if (secondl9999.count("(Enter /public/apps/gaussian/g16/l9999.exe)"))>1:
            secondl999split=secondl9999.split("(Enter /public/apps/gaussian/g16/l9999.exe)")[2].split("\\")
            # summary["secondl999split"]=secondl999split
            routeline2=secondl999split[11].replace(",",";")
            # print(routeline2)
            summary["routeline2"]=routeline2       
            summary["commentline2"]=(secondl999split[13].replace(",",";")) 
        readinfo = [natoms,dof,amu,t,p,zpve,S_elec,S_trans,S_rot]

        for i in routeline1.split():
            # print(i)
            if "stable" in i:
                summary["route_stable"]=i.replace(",",";")
            if "scf=" in i:
                summary["route_scf"]=i.replace(",",";")
            if "scrf" in i:
                summary["route_scrf"]=i.replace(",",";")
            if "EmpiricalDispersion" in i:
                summary["route_EmpiricalDispersion"]=i.replace(",",";")
            
    except:
        print(" ")
        # err=sys.exc_info()
        # print('python error in line %d: ' % err[2].tb_lineno)
        # print(err[1])
        # raise SystemExit(':::>_<:::%s Not Finished! FYI: %d out of %s frequencies found' % ("1.out",len(frequencies),dof))
    summary["TimeEnd"]=lines[-1][37:-2]
    Alphavirteigenvalues=[]
    for i in range(len(lines)):
        line = lines[i].lstrip()
        if line[:len("Alpha  occ. eigenvalues -- ")]=="Alpha  occ. eigenvalues -- ":
            Alphavirteigenvalues.append(i)
    summary["HOMO"]=lines[Alphavirteigenvalues[-1]].split()[-1]
    summary["LUMO"]=lines[Alphavirteigenvalues[-1]+1].split()[-5]
    summary["HOMO_LUMO_gap(ev)"]=((float(lines[Alphavirteigenvalues[-1]].split()[-1])+float(lines[Alphavirteigenvalues[-1]+1].split()[-5]))*27.2114)
    
if __name__ == '__main__':
    """ Usage: gopt_to_pdb.py -o ../1.out -p ../template.pdb """
    parser = argparse.ArgumentParser(description='generate pdbfiles from 1.out')
    parser.add_argument('-o', dest='output',default='1.out',help='output file')
    parser.add_argument('-p', dest='pdbf',default='template.pdb',help='template pdb file')
    parser.add_argument('-f', dest='frame',default="-1",help='select frame/range')

    args = parser.parse_args()
    pdbf = args.pdbf
    output = args.output

    pdb, res_info, tot_charge = read_pdb(pdbf)
#    map, xyz_i = get_ca(pdb)
    gmap, xyz_i = get_fatom(pdb)
    
    natoms = len(pdb)

    with open(output) as f:
        lines = f.readlines()

    p_start = []
    for i in range(len(lines)):
        if 'Standard orientation' in lines[i]:
            p_start.append(i+5)
    
    opt = []
    for j in range(len(p_start)):
        xyz = []
        for i in range(p_start[j],p_start[j]+natoms):
            v = lines[i].split()
            xyz.append([int(v[0]),int(v[1]),float(v[3]),float(v[4]),float(v[5])])
        opt.append(xyz)
    summary["Total_frozen_atoms"]=(len(get_fatom(pdb)[0]))
    summary["frozen_atoms"]=";".join(str(int) for int in (get_fatom(pdb)[0]))



    # summary["frozen_atoms"]=(get_fatom(pdb)[0])
    newopt=get_optl(lines)
    rot_opt = gaussian_opt_xyz(lines,natoms)#list
    # frequency1=gaussian_freq(lines)#tuple
    # atom_idx, freq, freqinfo = frequency1
    gaussnum=gaussian_num(output)#tuple
    nimag, nbasis, natoms1, charge, multip=gaussnum
    summary["NImag"]=nimag
    summary["nbasis"]=nbasis
    
    gaussatomname=gaussian_atom_names(lines,natoms)#list
    if int(args.frame) >= -1 and int(args.frame) < len(rot_opt):
        key = int(args.frame)
        xyz_c = array(rot_opt[key])
        (c_trans,U,ref_trans) = rms_fit(xyz_i,xyz_c[gmap])
        xyz_n = dot( xyz_c-c_trans, U ) + ref_trans
        sel_atom = update_xyz(pdb,xyz_n)
        if key == -1:
            name = str(len(rot_opt)-1)+'.pdb'
            write_pdb("cords.pdb",sel_atom)
            # summary["optimized_structure"]=sel_atom

with open (f"cords","w") as writestart:
    with open("cords.pdb",'r') as po:
        lines = po.readlines()
        summary["Optimized_pdb"]=lines
    for i in lines:
        writestart.writelines(i)
    # for i in frequency1:
    #     writestart.writelines(str('%s\n' %i))
    for i in firstl999split:
        writestart.writelines(str('%s\n' %i))
    if (secondl9999.count("(Enter /public/apps/gaussian/g16/l9999.exe)"))>1:
        for i in secondl999split:
            writestart.writelines(str('%s\n' %i))  
    for i in gaussatomname:
        writestart.writelines('%s\n' % i)
    with open("1.out",'r') as fo:
        lines = fo.readlines()
        k=0
        for line in lines[Atomic_Atomic_Spin_Densities[-1]:Atomic_Atomic_Spin_Densities[-1]+(2+natoms)]:
            if "H" in line:
                k=k+1
        for i in lines[Atomic_Atomic_Spin_Densities[-1]:Atomic_Atomic_Spin_Densities[-1]+(5+natoms+k)]:
            writestart.writelines(i)

    


    for key, value in summary.items(): 
        writestart.write('%s:%s\n' % (key, value))
        # if "," in str(value):
        #     value=str(value.replace(",", ";"))
            # print(value)
    
    writestart.write(json.dumps(summary,indent=4))
        # print("=",value,end=("\n"))
    # joined= "".join(str(key) +"="+ str(value) for key, value in summary.items())
    summary.pop("Optimized_pdb")
    key_joined="".join(f"{key}," for key,value in summary.items())
    value_joined= "".join(f"{value}," for key,value in summary.items())
    print("  ")
    print(key_joined)
    print("  ")
    print(value_joined)
    print("   \n********cords(contains json format) and cords.pdb is created************")
        # print(''.join(['{0}{1}'.format("=", v) for v in dictionary.iteritems()]))
        # print(key)
        
