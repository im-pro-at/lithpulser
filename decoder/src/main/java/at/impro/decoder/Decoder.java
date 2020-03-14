//--------------------------------------------------------------------------------
// Company: im-pro.at
// Engineer: Patrick Knöbel
//
//   GNU GENERAL PUBLIC LICENSE Version 3
//
//----------------------------------------------------------------------------------
package at.impro.decoder;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;

public class Decoder {
    
    public static void main(String[] args) {

        File dir = new File("runs");

        if (!(dir.exists() && dir.isDirectory())) {
            System.out.println("Folder runs not found! (" + dir.getAbsolutePath() + ")");
            return;
        }

        for (File input : dir.listFiles()) {
            if (!input.getName().endsWith(".bin")) {
                continue;
            }
            File output = new File(input.getParent(), input.getName() + ".csv");
            if (output.exists()) {
                continue;
            }
            System.out.println("Converting " + input + " to " + output + " ...");
            try (DataInputStream in = new DataInputStream(new BufferedInputStream(new FileInputStream(input)))) {
                output.createNewFile();
                try (PrintWriter out = new PrintWriter(new OutputStreamWriter(new BufferedOutputStream(new FileOutputStream(output)), "UTF-8"))) {
                    DateWrapper w = new DateWrapper();

                    out.write(w.getHeader());

                    boolean hasdata = true;
                    while (hasdata) {
                        long data = 0;
                        for (int i = 0; i < 8; i++) {
                            int b = in.read();
                            if (b == -1) {
                                if (i != 0) {
                                    System.out.println(input + " is not allined! Data maybe incomplete!");
                                }
                                hasdata = false;
                                break;
                            } else {
                                data |= ((long) b) << (i * 8);
                            }
                        }
                        if (hasdata) {
                            //decode CS
                            int cs = (int) (data >> 1) & ((1 << 4) - 1);
                            if ((w.hasI() || w.hasT()) && cs != w.getCS()) {
                                out.write(w.getLineAndClear());
                            }
                            if (data % 2 == 0) {
                                //Sequence Start Log
                                if (w.hasT()) {
                                    out.write(w.getLineAndClear());
                                }
                                w.setCS(cs);
                                w.setT((data >> 5) & ((((long) 1) << 52) - 1));
                            } else {
                                //Input Counter Log
                                if (w.hasI()) {
                                    out.write(w.getLineAndClear());
                                }
                                w.setCS(cs);
                                w.setI((data >> 5) & ((((long) 1) << 26) - 1), (data >> 31) & ((((long) 1) << 26) - 1));
                            }
                            if ((w.hasI() && w.hasT())) {
                                out.write(w.getLineAndClear());
                            }
                        } else if (w.hasT() || w.hasI()) {
                            out.write(w.getLineAndClear());
                        }
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }
}
