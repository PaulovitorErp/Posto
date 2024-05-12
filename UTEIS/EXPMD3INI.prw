#INCLUDE 'Protheus.ch'
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} User Function EXPMD3INI
    
Exporta a MD3 gerando um smartclient.ini

@type  Function
@author Danilo
@since 24/03/2021
@version 1
@param cPath, caminho para salvar aquivo
@param cCpLable, Campo a considerar como nome da comunicação
@return 
@example
(examples)
@see (links_or_references)
/*/
//U_EXPMD3INI("C:\Temp")
User Function EXPMD3INI(cPath,cCpLable)
    
    Local cQry := ""
    //Local CRLF := chr(13)+chr(10)
    Local cConfig := ""
    Local cDrivers := ""
    Local cComunic := ""
    Default cPath := ""
    Default cCpLable := "MD3_DESCRI" //"'O_'+MD3_EMP+'_'+MD3_FIL+'_PDV'+Alltrim(MD4_XPDV)"

    if empty(cPath)
        MsgAlert("Informe o caminho para salvar arquivo")
        Return
    endif

    cConfig := "[config]"+CRLF
    cConfig += "lastmainprog=SIGAMDI,APSDU,SIGACFG"+CRLF
    cConfig += "envserver=HOSTS"+CRLF
    cConfig += CRLF

    cDrivers := "[drivers]"+CRLF
    cDrivers += "active="


    cQry := "SELECT * 
    cQry += " FROM "+RetSqlName("MD3")+" MD3 "
    cQry += " INNER JOIN "+RetSqlName("MD4")+" MD4 "
    cQry += "    ON MD4.D_E_L_E_T_ = ' ' AND MD4_FILIAL = MD3_FILIAL AND MD4_CODIGO = MD3_CODAMB "
    cQry += " WHERE MD3.D_E_L_E_T_ = ' ' "
    cQry += " AND MD3_TIPO = 'R' "
    cQry += " ORDER BY MD3_EMP, MD3_FIL, MD3_DESCRI "

	If Select("QRYMD3") > 0
		QRYMD3->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYMD3" // Cria uma nova area com o resultado do query
	While QRYMD3->(!Eof())

        cDrivers += Upper(Alltrim(QRYMD3->&(cCpLable))) + ","

        cComunic += "["+Upper(Alltrim(QRYMD3->&(cCpLable)))+"]"+CRLF
        cComunic += "server="+Alltrim(QRYMD3->MD3_IP)+CRLF
        cComunic += "port="+Alltrim(QRYMD3->MD3_PORTA)+CRLF
        cComunic += CRLF

        QRYMD3->(DbSkip())
	EndDo
	QRYMD3->(DbCloseArea())

    cDrivers := SubStr(cDrivers,1,len(cDrivers)-1)
    cDrivers += CRLF+CRLF

    MemoWrite(cPath + "\smartclient.ini", cConfig+cDrivers+cComunic )

    MsgInfo("Concluido!")

Return 
