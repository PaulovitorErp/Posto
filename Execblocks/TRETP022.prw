#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP022
O ponto de entrada F040TRVSA1 permite travar ou destravar os registros da Tabela de Cliente - SA1, na rotina Clientes - MATA030.
Essa ação é possível mesmo se os registros estiverem sendo utilizados por uma thread.

O ponto de entrada está presente nas funções FA040AxAlt e GeraParcSe1 da rotina Contas a Receber - FINA040 e A040DupRec e AtuSalDup do fonte -(MATXATU)

@author Totvs GO
@since 20/04/2018
@version 1.0

@return Lógico

@type function
/*/
User Function TRETP022()

    Local lRet := .T.

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return lRet
    EndIf

    //Conout(">> F040TRVSA1 - INICIO - Permite travar ou destravar os registros da SA1. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")
    //Conout(">> F040TRVSA1 - ProcName(): "+ProcName()+"")

    //Conout("")
    //Conout("PE F040TRVSA1 - cEmpAnt / cFilAnt: " + CEMPANT +"/"+ CFILANT)
    //Conout("PE F040TRVSA1 - SM0: " + AllTrim(SM0->M0_CODFIL) + " - "+ SM0->M0_CGC +"/"+ SM0->M0_NOMECOM)
    //Conout("")

    //foi constatado que em algumas situações a SM0 consta desposicionada
    If SM0->M0_CODIGO <> CEMPANT .or. SM0->M0_CODFIL <> CFILANT
        //Conout("")
        //Conout("	ATENÇÃO - SM0 NÃO posicionada conforme CFILANT: " + CFILANT + " / M0_CODFIL: " + SM0->M0_CODFIL)
        If !SM0->( DbSeek(CEMPANT + CFILANT) )		
            //Conout("	ATENÇÃO - NÃO foi possível posicionar SM0 conforme CFILANT: "+ CFILANT)
        Else
            //Conout("	cEmpAnt / cFilAnt: " + CEMPANT +"/"+ CFILANT)
            //Conout("	SM0: " + AllTrim(SM0->M0_CODFIL) + " - "+ SM0->M0_CGC +"/"+ SM0->M0_NOMECOM)	
        EndIf
        //Conout("")
    EndIf

    If IsInCallStack("LJGRVBATCH")
        lRet := .F. //lRet:= MsgYesNo("Deseja travar os registros da tabela SA1 ?")
        //Conout(">> F040TRVSA1 - Nao ira travar CLIENTE: "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+"") 
    EndIf

    //Conout(">> F040TRVSA1 - FIM - Permite travar ou destravar os registros da SA1. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")

Return lRet
