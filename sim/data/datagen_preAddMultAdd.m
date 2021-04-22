function [] = generate_data_preAddMultAdd(AWIDTH, BWIDTH, CWIDTH, data_number)   
    A_min = -2.^(AWIDTH-1);
    A_max =  2.^(AWIDTH-1)-1;
    B_min = -2.^(BWIDTH-1);
    B_max =  2.^(BWIDTH-1)-1;
    C_min = -2.^(CWIDTH-1);
    C_max =  2.^(CWIDTH-1)-1;
    D_min = -2.^(BWIDTH+CWIDTH);
    D_max =  2.^(BWIDTH+CWIDTH)-1;
    
    A = randi([A_min A_max], 1, data_number/2);
    B = randi([B_min B_max], 1, data_number/2);
    C = randi([C_min C_max], 1, data_number/2);
    D = randi([D_min D_max], 1, data_number/2);
    WT = [A ; B ;C ; D];
    
    OUTP = (A+B).*C+D;
    OUTM = (A-B).*C+D;
    
    FIN  = fopen('preAddMultAdd_matlab_in.txt', 'w');
    fprintf(FIN, '%d %d %d %d 0\n', WT);
    fprintf(FIN, '%d %d %d %d 1\n', WT);
    fclose(FIN);
    
    FOUT = fopen('preAddMultAdd_matlab_out.txt', 'w');
    fprintf(FOUT, '%d\n', OUTP);
    fprintf(FOUT, '%d\n', OUTM);
    fclose(FOUT);

    FIN  = fopen('preAddMultAdd_matlab_in_errors.txt', 'w');
    fprintf(FIN, '%d %d %d %d 1\n', WT);
    fprintf(FIN, '%d %d %d %d 1\n', WT);
    fprintf(FIN, '0 0 0 0 0\n');
    fclose(FIN);
    
    FOUT = fopen('preAddMultAdd_matlab_out_errors.txt', 'w');
    fprintf(FOUT, '%d\n', OUTP);
    fprintf(FOUT, '%d\n', OUTM);
    fclose(FOUT);
end
