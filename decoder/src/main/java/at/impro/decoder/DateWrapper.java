//--------------------------------------------------------------------------------
// Company: im-pro.at
// Engineer: Patrick Knöbel
//
//   GNU GENERAL PUBLIC LICENSE Version 3
//
//----------------------------------------------------------------------------------
package at.impro.decoder;

class DateWrapper {
    
    long t = -1;
    long i0 = -1;
    long i1 = -1;
    int cs = -1;

    void setCS(int cs) {
        this.cs = cs;
    }

    int getCS() {
        return this.cs;
    }

    void setT(long t) {
        this.t = t;
    }

    boolean hasT() {
        return t != -1;
    }

    void setI(long i0, long i1) {
        this.i0 = i0;
        this.i1 = i1;
    }

    boolean hasI() {
        return this.i0 != -1 || this.i1 != -1;
    }

    String getHeader() {
        return "T;CS;I0;I1\n";
    }

    String getLineAndClear() {
        String r = this.t + ";" + this.cs + ";" + this.i0 + ";" + this.i1 + "\n";
        this.t = -1;
        this.cs = -1;
        this.i0 = -1;
        this.i1 = -1;
        return r;
    }
    
}
