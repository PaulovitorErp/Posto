#INCLUDE "PROTHEUS.CH"

#DEFINE ENTIRE		"1"  //carga inteira
#DEFINE INCREMENTAL	"2"  //carga incremental

Static lKpXPOSTO 		:= SuperGetMv("KP_XPOSTO",,.F.)

// O protheus necessita ter ao menos uma função pública para que o fonte seja exibido na inspeção de fontes do RPO.
User Function UREDISLB() ; Return

//-------------------------------------------------------------------
/*/{Protheus.doc} RedisLoadTempTableExport
Classe com dados utilizados para criar a tabela temporaria 
usada na exportacao dos dados da carga
 
@author Vendas CRM
@since 28/06/2012
/*/
//--------------------------------------------------------------------
	Class RedisLoadTempTableExport

		Data oTable
		Data cBranch
		Data cExportType
		Data cNameTempTable

		Data cSelect
		Data cFrom
		Data cWhere
		Data cSelectSBZ
		Data cFromSBZ
		Data cWhereSBZ
		Data cQrySB1SBZ
		Data nQtyRecords

		//Private methods - esses metodos nao devem ser utilizados fora desta classe
		Method CreateCompleteTempTable()
		Method CreateSpecialTempTable()
		Method UpdMSEXPCompleteTable()
		Method UpdMSEXPSpecialTable()
		Method GetQueryMemo() // auxilia a criacao da query para trazer os campos memos reais (de acordo com a sintaxe do banco usado)

		//Public methods
		Method New()
		Method Initialize()
		Method CreateTempTable()
		Method SetQtyRecords()
		Method UpdateMSEXP()
		Method UpdateRecno()
		Method IsFirstExport()
		Method SetQtyRecSQL()
		Method GetFullQuery()

	EndClass


//------------------------------------------------------------------------------------------------
/*/{Protheus.doc} New()
Inicializa o objeto do tipo RedisLoadTempTableExport

@param oTable tabela a ser exportada
@param cBranch filial
@param cExportType Tipo da exportacao (1 = inteira / 2 = incremental)
@param cNameTempTable nome da tabela temporaria que sera criada 
 
@return Self 
@author Vendas CRM
@since 28/06/2012
/*/
//------------------------------------------------------------------------------------------------
Method New(oTable, cBranch, cExportType, cNameTempTable) Class RedisLoadTempTableExport

	Self:oTable			:= oTable
	Self:cBranch		:= cBranch
	Self:cExportType	:= cExportType
	Self:cNameTempTable	:= cNameTempTable
	Self:nQtyRecords	:= 0

	Self:Initialize()

Return



//------------------------------------------------------------------------------------------------
/*/{Protheus.doc} Initialize()
Inicializa o objeto do tipo RedisLoadTempTableExport
 

@author Vendas CRM
@since 28/06/2012
/*/
//------------------------------------------------------------------------------------------------
Method Initialize() Class RedisLoadTempTableExport

	Local cTablePrefix			:= ""
	Local cBranchUsed			:= ""
	Local lSB1ExclusiveTable	:= .F.
	Local cSqlMemo				:= ""
	Local cMV_ARQPROD   		:= ""
	Local aStructSB1 			:= {}
	Local aStructSBZ 			:= {}
	Local cSelectSB1 			:= ""
	Local cSelectSBZ 			:= ""
	Local nX 					:= 0
	Local cField				:= ""
	Local nPos 					:= 0
	Local cPRV_SB0 				:= "B0_PRV1"
	Local cSQLSyntax			:= ""

	DO CASE
	CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadCompleteTable")

		cSQLSyntax := Self:GetFullQuery()

		cTablePrefix	:= If(SubStr(Self:oTable:cTable,1,1) == "S", SubStr(Self:oTable:cTable,2,3), Self:oTable:cTable)

		//monta query para trazer os dados
		Self:cSelect	:= " SELECT " + cSQLSyntax + ", D_E_L_E_T_ DEL, R_E_C_N_O_ REC  "
		Self:cFrom 		:= " FROM " + RetSqlName(Self:oTable:cTable)
		Self:cWhere 	:= " WHERE " +  cTablePrefix + "_FILIAL" + " = '" + Self:cBranch + "' "
		//Self:cWhere 	+= " AND D_E_L_E_T_ = ' ' "

		//Se for incremental exporta apenas os registros que foram alterados ou incluidos
		If Self:cExportType == INCREMENTAL
			Self:cWhere += " AND " + cTablePrefix + "_MSEXP = '"+ Space(8) + "'"
		EndIf


	CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadSpecialTable")

		//Retorna o campo referente a tabela de preco selecionada na tela do Wizard.
		If FindFunction("Lj1149Tab")
			cPRV_SB0 := "B0_PRV" + Lj1149Tab()
		EndIf

		//Verifica se os dados de indicadores de produto serao considerados pela tabela "SB1" ou pela tabela "SBZ"
		cMV_ARQPROD := SuperGetMV("MV_ARQPROD",.F.,"SB1")

		lSB1ExclusiveTable := AllTrim(FWModeAccess("SB1",3)) == "E"

		If lSB1ExclusiveTable
			cBranchUsed := Self:cBranch
		Else
			cBranchUsed := xFilial("SB1")
		EndIf

		//monta a query pra juntar a SB1 com a SB0 na SBI
		//se qualquer registro estiver deletado (SB1 ou SB0) deleta o registro na SBI
		Self:cSelect := " SELECT " + RetSqlName('SB0') + "."+cPRV_SB0+" B1_PRV, "
		Self:cSelect += RetSqlName('SB0') + ".B0_ALIQRED B1_ALIQRED,"
		Self:cSelect += " CASE "
		Self:cSelect += " 	WHEN " + RetSqlName('SB1') + ".D_E_L_E_T_ = '*' THEN '*' "
		Self:cSelect += " 	WHEN " + RetSqlName('SB0') + ".D_E_L_E_T_ = '*' THEN '*' "
		Self:cSelect += " 	ELSE ' ' "
		Self:cSelect += " END DEL, "
		Self:cSelect +=  RetSqlName('SB1') + ".* " + cSqlMemo
		Self:cFrom := " FROM " + RetSqlName('SB1')
		Self:cFrom += " LEFT JOIN " + RetSqlName('SB0') + " ON " + RetSqlName('SB1') + ".B1_COD = " + RetSqlName('SB0') + ".B0_COD "
		Self:cWhere = " WHERE B1_FILIAL = '" + cBranchUsed + "' AND "
		Self:cWhere += " B0_FILIAL = '" + Self:cBranch + "' "

		//Se for incremental exporta apenas os registros que foram alterados ou incluidos
		If Self:cExportType == INCREMENTAL
			Self:cWhere += " AND (B1_MSEXP = '"+ Space(8) + "' OR B0_MSEXP = '"+ Space(8) + "' ) "
		EndIf

		If cMV_ARQPROD == "SBZ"

			aStructSB1 := SB1->(DBStruct())
			aStructSBZ := SBZ->(DBStruct())

			//Compara a estrutura das tabelas SB1 e SBZ, para somente considerar os campos da SBZ que tambem existem na SB1 com o mesmo nome
			For nX := 1 To Len(aStructSB1)
				If aStructSB1[nX][2] == 'M' //Desconsidera campo MEMO Real
					Loop
				EndIf
				cField 		:= aStructSB1[nX][1]
				cSelectSB1 	+= cField + ","
				//Verifica se existe o campo da SB1 na SBZ
				If cField <> "B1_FILIAL" .And. ( nPos := aScan( aStructSBZ, { |x| SubStr(x[1],3) == SubStr(cField,3) } ) ) > 0
					//Caso exista sera considerada a informacao da SBZ
					cSelectSBZ += aStructSBZ[nPos][1] + " " + cField + ","
				Else
					cSelectSBZ += cField + ","
				EndIf
			Next nX

			//Retira a ultima virgula
			cSelectSB1 := Left(cSelectSB1,Len(cSelectSB1)-1)
			cSelectSBZ := Left(cSelectSBZ,Len(cSelectSBZ)-1)

			//Query para filtrar registros da tabela SBZ
			Self:cSelectSBZ := "SELECT " + RetSqlName('SB0') + "."+cPRV_SB0+" B1_PRV, "
			Self:cSelectSBZ += RetSqlName('SB0') + ".B0_ALIQRED B1_ALIQRED,"
			Self:cSelectSBZ += " CASE "
			Self:cSelectSBZ += " 	WHEN " + RetSqlName('SB1') + ".D_E_L_E_T_ = '*' THEN '*' "
			Self:cSelectSBZ += " 	WHEN " + RetSqlName('SB0') + ".D_E_L_E_T_ = '*' THEN '*' "
			Self:cSelectSBZ += " 	ELSE ' ' "
			Self:cSelectSBZ += " END DEL, "
			Self:cSelectSBZ += cSelectSBZ + cSqlMemo
			Self:cFromSBZ 	:= " FROM " + RetSqlName('SB1')
			Self:cFromSBZ  	+= " LEFT JOIN " + RetSqlName('SB0') + " ON (" + RetSqlName('SB1') + ".B1_COD = " + RetSqlName('SB0') + ".B0_COD) "
			Self:cFromSBZ 	+= " INNER JOIN " + RetSqlName('SBZ') + " ON (" + RetSqlName('SB1') + ".B1_COD = " + RetSqlName('SBZ')  + ".BZ_COD) "
			Self:cWhereSBZ 	:= " WHERE B1_FILIAL = '" + cBranchUsed + "' "
			Self:cWhereSBZ 	+= "   AND B0_FILIAL = '" + Self:cBranch + "' "
			Self:cWhereSBZ 	+= "   AND BZ_FILIAL = '" + Self:cBranch + "' "
			Self:cWhereSBZ 	+= "   AND " + RetSqlName('SBZ') + ".D_E_L_E_T_ = ' ' "
			//Se for incremental exporta apenas os registros que foram alterados ou incluidos
			If Self:cExportType == INCREMENTAL
				Self:cWhereSBZ += " AND (B1_MSEXP = '"+ Space(8) + "' OR B0_MSEXP = '"+ Space(8) + "' OR BZ_MSEXP = '"+ Space(8) + "'  ) "
			EndIf

			Self:cQrySB1SBZ := Self:cSelectSBZ + Self:cFromSBZ + Self:cWhereSBZ

			Self:cQrySB1SBZ += " UNION "  //Uniao entre as queries BSZ e SB1

			//Query para filtrar registros da tabela SB1
			Self:cQrySB1SBZ += " SELECT " + RetSqlName('SB0') + "."+cPRV_SB0+" B1_PRV, "
			Self:cQrySB1SBZ += RetSqlName('SB0') + ".B0_ALIQRED B1_ALIQRED,"
			Self:cQrySB1SBZ += " CASE "
			Self:cQrySB1SBZ += "  WHEN " + RetSqlName('SB1') + ".D_E_L_E_T_ = '*' THEN '*' "
			Self:cQrySB1SBZ += "  WHEN " + RetSqlName('SB0') + ".D_E_L_E_T_ = '*' THEN '*' "
			Self:cQrySB1SBZ += "	ELSE ' ' "
			Self:cQrySB1SBZ += " END DEL, "
			Self:cQrySB1SBZ += cSelectSB1 + cSqlMemo
			Self:cQrySB1SBZ += " FROM " + RetSqlName('SB1')
			Self:cQrySB1SBZ += " LEFT JOIN " + RetSqlName('SB0') + " ON (" + RetSqlName('SB1') + ".B1_COD = " + RetSqlName('SB0') + ".B0_COD ) "
			Self:cQrySB1SBZ += " WHERE B1_FILIAL = '" + cBranchUsed + "' "
			Self:cQrySB1SBZ += "   AND B0_FILIAL = '" + Self:cBranch + "' "
			Self:cQrySB1SBZ += "   AND NOT EXISTS ( SELECT BZ_COD "
			Self:cQrySB1SBZ += "                      FROM " + RetSqlName('SBZ')
			Self:cQrySB1SBZ += "                     WHERE BZ_FILIAL = '" + Self:cBranch + "' "
			Self:cQrySB1SBZ += "                       AND BZ_COD = " + RetSqlName('SB1') + ".B1_COD "
			Self:cQrySB1SBZ += "                       AND " + RetSqlName('SBZ') + ".D_E_L_E_T_ = ' ' ) "
			//Se for incremental exporta apenas os registros que foram alterados ou incluidos
			If Self:cExportType == INCREMENTAL
				Self:cQrySB1SBZ += " AND (B1_MSEXP = '"+ Space(8) + "' OR B0_MSEXP = '"+ Space(8) + "' ) "
			EndIf
		EndIf

	ENDCASE

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} GetQueryMemo()
auxilia a criacao da query para trazer os campos memos reais (de acordo com a sintaxe do banco usado)

@return cQuery //query sql para trazer o memo real. Sera concatenada ao comando completo no metodo Initialize desta classe
@author Vendas CRM
@since 29/10/2012
/*/
//-----------------------------------------------------------------------
Method GetQueryMemo() Class RedisLoadTempTableExport
	Local cQuery 		:= ""
	Local aStruct		:= {}
	Local nI			:= 0
	Local cTypeDB		:= TCGetDB()

//verifica se existe algum Memo real na estrutura da tabela
	aStruct := (Self:oTable:cTable)->( DBStruct() )
	For nI:= 1 to Len(aStruct)
		If aStruct[nI][2] == "M"
			//Monta a query para tratar o campo Memo real

			//Este P.E. foi criado pelo motivo de sintaxe diferente de cada SGBD para converter um campo Memo Real (BLOB) para Caractere
			If ExistBlock("Lj1170MM")
				cQuery += ", " + ExecBlock("Lj1170MM",.F.,.F.,{Self:oTable:cTable,aStruct[nI][1]}) + " " + aStruct[nI][1]
			Else
				//Tratamento apenas para SQL Server e DB2.
				If "MSSQL" $ cTypeDB
					cQuery += " , CONVERT(VARCHAR(4000),CONVERT(VARBINARY(4000)," + aStruct[nI][1] + " )) " + aStruct[nI][1]
				ElseIf "DB2" $ cTypeDB
					// Query em Campos Memo no DB2 infelizmente não funciona, não traz resultado nenhum
					cQuery += ""
				EndIf
				// *** O B S E R V A C A O :
				//Para banco ORACLE existia o seguinte tratamento: utl_raw.cast_to_varchar2(CAMPO)
				//Porem, soh funciona se estiver instalado o pacote UTL_RAW no banco Oracle. Por isso, foi tirado o tratamento p/ Oracle
				//onde foi criado o P.E. "Lj1170MM" p/ que o cliente trate a sintaxe conforme o pacote que ele possuir instalado no banco.
			EndIf
		EndIf
	Next nI

Return cQuery

//----------------------------------------------------------------------
/*/{Protheus.doc} CreateTempTable()
Cria tabela temporaria de acordo com o tipo da exportacao 
 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method CreateTempTable() Class RedisLoadTempTableExport
	DO CASE
	CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadCompleteTable")
		Self:CreateCompleteTempTable()

	CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadSpecialTable")
		Self:CreateSpecialTempTable()

	ENDCASE
Return

//-------------------------------------------------------------------------------------------------
/*/{Protheus.doc} CreateCompleteTempTable()
Cria uma tabela temporaria com os filtros necessarios para realizar a exportacao do tipo completa. 
Faz o tratamento do tipo de dados baseado nos campos da tabela recebida em oCompleteTable

@author Vendas CRM
@since 28/06/2012
/*/
//--------------------------------------------------------------------------------------------------
Method CreateCompleteTempTable() Class RedisLoadTempTableExport

	Local cQuery		:= ""
	Local aStruct		:= {}
	Local nI			:= 0

	cQuery := ChangeQuery(Self:cSelect + Self:cFrom + Self:cWhere)

// Cria tabela temporaria trazendo apenas os registros que devem ser exportados
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery),Self:cNameTempTable, .F., .T.)
	//LjGrvLog( "Carga","Exportacao do tipo completa ", cQuery)

//trata campos do tipo data, numerico e logico
	aStruct := (Self:oTable:cTable)->(DBStruct())
	For nI := 1 to len(aStruct)
		If (aStruct[nI][2] $ 'DNL')
			TCSetField(Self:cNameTempTable, aStruct[nI,1], aStruct[nI,2],aStruct[nI,3],aStruct[nI,4])
		Endif
	Next

Return

//----------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} CreateSpecialTempTable()
Cria uma tabela temporaria com os filtros necessarios para realizar a exportacao do tipo especial. 
Faz o tratamento do tipo de dados baseado nos campos da SB1 e SB0 
 
@author Vendas CRM
@since 28/06/2012
/*/
//----------------------------------------------------------------------------------------------------------
Method CreateSpecialTempTable() Class RedisLoadTempTableExport

	Local cQuery		:= ""
	Local aSB1Struct	:= {}
	Local aSB0Struct	:= {}
	Local nI			:= 0
	Local nJ			:= 0

	If !Empty(Self:cQrySB1SBZ)
		cQuery := ChangeQuery(Self:cQrySB1SBZ)
	Else
		cQuery := ChangeQuery(Self:cSelect + Self:cFrom + Self:cWhere)
	EndIf

// Cria tabela temporaria "SB1TMP" trazendo apenas os registros que devem ser exportados
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery), Self:cNameTempTable, .F., .T.)
	//LjGrvLog( "Carga","Exportacao do tipo especial ", cQuery)

//trata campos do tipo data, numerico e logico
	aSB1Struct := SB1->(dbStruct())
	For nI := 1 to len(aSB1Struct)
		If (aSB1Struct[nI][2] $ 'DNL')
			TCSetField(Self:cNameTempTable,aSB1Struct[ni,1], aSB1Struct[ni,2],aSB1Struct[ni,3],aSB1Struct[ni,4])
		Endif
	Next

//trata o campo de preco que vem da SB0
	aSB0Struct := SB0->(dbStruct())
	For nJ := 1 to len(aSB0Struct)
		If (aSB0Struct[nJ][1] == 'B0_PRV1')
			TCSetField(Self:cNameTempTable, 'B1_PRV', aSB0Struct[nJ,2],aSB0Struct[nJ,3],aSB0Struct[nJ,4])
		Endif
	Next

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} SetQtyRecords()
Define o total de registros da tabela temporaria que sera exportada
 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method SetQtyRecords() Class RedisLoadTempTableExport
	
	Local nTotal := 0

	DbselectArea(Self:cNameTempTable)
	DbGoTop()
	While (Self:cNameTempTable)->(!EOF())
		nTotal++
		(Self:cNameTempTable)->(DbSkip())
	End
	Self:nQtyRecords := nTotal

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} UpdMSEXPCompleteTable()
Atualiza os campos MSEXP dos registros exportados 
 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method UpdMSEXPCompleteTable(cWhereRec) Class RedisLoadTempTableExport

	Local cQuery		:= ""
	Local cTablePrefix	:= ""
	Local nStatus		:= 0
	Local lB1MEmp		:= SuperGetMv("MV_LJB1MEMP",,.F.)						//Informa se utiliza o arquivo SB1 compartilhado para multiplas empresas
	Local lUpdate		:= .T.
	Default cWhereRec   := ""

	cTablePrefix	 := If(SubStr(Self:oTable:cTable,1,1) == "S", SubStr(Self:oTable:cTable,2,3), Self:oTable:cTable)

	If AllTrim(cTablePrefix) == "B1" .AND. lB1MEmp .AND. !IsBlind()
		lUpdate := MsgYesNo("Esta é a ultima empresa para geração desta carga de produtos?","Atenção")//"Esta é a ultima empresa de geração desta carga de produtos?"//"Atenção"
	EndIf

	If lUpdate
		cQuery := "UPDATE " + RetSqlName(Self:oTable:cTable)
		cQuery += " SET " + cTablePrefix + "_MSEXP = '" + DtoS(dDataBase) + "' "
		if lKpXPOSTO
			cQuery += " , " + cTablePrefix + "_HREXP = '" + space(8) + "' "
		else
			cQuery += " , " + cTablePrefix + "_HREXP = '" + Left(Time(),8) + "' "
		endif
		cQuery += Self:cWhere
		If !Empty(cWhereRec)
			cQuery += cWhereRec
		EndIf

		nStatus := TCSQLEXEC(cQuery)
	EndIf

	If nStatus < 0
		conout("Não foi possível atualizar os campos de controle MSEXP e HREXP.")
	EndIf

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} UpdMSEXPSpecialTable()
Atualiza os campos MSEXP dos registros exportados 
 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method UpdMSEXPSpecialTable(cWhereRec) Class RedisLoadTempTableExport

	Local cQuery				:= ""
	Local nStatus				:= 0
	Local lSQLite 		    	:= AllTrim(Upper(GetSrvProfString("RpoDb",""))) == "SQLITE" //PDVM/Fat Client
	Default cWhereRec   		:= ""

//Atualiza MSEXP e HREXP da SB0
	cQuery := " UPDATE " + RetSqlName("SB0")  + " SET B0_MSEXP = '" + DtoS(dDataBase) + "'"
	if lKpXPOSTO
		cQuery += " , B0_HREXP = '" + space(8) + "' "
	else
		cQuery += " , B0_HREXP = '" + Left(Time(),8) + "' "
	endif
	cQuery += " WHERE R_E_C_N_O_ "+Iif(lSQLite,"=","IN")+" ( SELECT " + RetSqlName("SB0")  + ".R_E_C_N_O_ " + Self:cFrom + Self:cWhere + Iif(!Empty(cWhereRec),cWhereRec,"") + ") "

	nStatus := TCSQLEXEC(cQuery)

	If nStatus < 0
		conout("Não foi possível atualizar os campos de controle B0_MSEXP e B0_HREXP.")
	EndIf

//Atualiza MSEXP e HREXP da SB1
	cQuery := " UPDATE " + RetSqlName("SB1")  + " SET B1_MSEXP = '" + DtoS(dDataBase) + "'"
	if lKpXPOSTO
		cQuery += " , B1_HREXP = '" + space(8) + "' "
	else
		cQuery += " , B1_HREXP = '" + Left(Time(),8) + "' "
	endif
	cQuery += " WHERE R_E_C_N_O_ "+Iif(lSQLite,"=","IN")+" ( SELECT " + RetSqlName("SB1")  + ".R_E_C_N_O_ " + Self:cFrom + Self:cWhere + Iif(!Empty(cWhereRec),cWhereRec,"") + ") "

	nStatus := TCSQLEXEC(cQuery)

	If nStatus < 0
		conout("Não foi possível atualizar os campos de controle B1_MSEXP e B1_HREXP.")
	EndIf

//Atualiza MSEXP e HREXP da SBZ
	If !Empty(Self:cFromSBZ) .And. !Empty(Self:cWhereSBZ)
		cQuery := " UPDATE " + RetSqlName("SBZ")  + " SET BZ_MSEXP = '" + DtoS(dDataBase) + "'"
			if lKpXPOSTO
			cQuery += " , BZ_HREXP = '" + space(8) + "' "
		else
			cQuery += " , BZ_HREXP = '" + Left(Time(),8) + "' "
		endif
		cQuery += " WHERE R_E_C_N_O_ "+Iif(lSQLite,"=","IN")+" ( SELECT " + RetSqlName("SBZ")  + ".R_E_C_N_O_ " + Self:cFromSBZ + Self:cWhereSBZ + Iif(!Empty(cWhereRec),cWhereRec,"") + ") "

		nStatus := TCSQLEXEC(cQuery)

		If nStatus < 0
			conout("Não foi possível atualizar os campos de controle BZ_MSEXP e BZ_HREXP.")
		EndIf
	EndIf

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} UpdateMSEXP()
Atualiza os campos MSEXP dos registros exportados 
 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method UpdateMSEXP() Class RedisLoadTempTableExport

	If Self:nQtyRecords	> 0
		DO CASE
		CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadCompleteTable")
			Self:UpdMSEXPCompleteTable()

		CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadSpecialTable")
			Self:UpdMSEXPSpecialTable()

		ENDCASE
	EndIf

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} UpdateRecno()
Atualiza os campos MSEXP de um registro específico exportado
 
@author Vendas CRM
@since 17/03/2021
/*/
//-----------------------------------------------------------------------
Method UpdateRecno(nRecNo) Class RedisLoadTempTableExport
	Local cWhereRec := ""

	If nRecNo > 0
		cWhereRec := " AND R_E_C_N_O_ = "+cValToChar(nRecNo)+" "
		DO CASE
		CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadCompleteTable")
			Self:UpdMSEXPCompleteTable(cWhereRec)

		CASE Lower(GetClassName( Self:oTable )) == Lower("RedisLoadSpecialTable")
			Self:UpdMSEXPSpecialTable(cWhereRec)

		ENDCASE
	EndIf

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} IsFirstExport()
determina se é a primeira exportacao inteira

@return lRet True, se for a primeira exportacao inteira 
@author Vendas CRM
@since 28/06/2012
/*/
//-----------------------------------------------------------------------
Method IsFirstExport() Class RedisLoadTempTableExport

	Local cQuery		:= ""
	Local nTotRec		:= 0
	Local lRet		:= .F.

//verifica se ja houve alguma exportacao da tabela alem dessa que acabou de ser executada
	cQuery := " SELECT COUNT(*) TOTREC FROM " + RetSqlName('MBV') + " WHERE MBV_TABELA = '" + Self:oTable:cTable + "' AND MBV_QTDREG > 0"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery),'TOTTMP', .F., .T.)
	nTotRec := TOTTMP->TOTREC
	TOTTMP->(dbCloseArea())

	lRet := nTotRec <= 1

Return lRet

//----------------------------------------------------------------------
/*/{Protheus.doc} SetQtyRecSQL()
Define o total de registros da tabela temporaria que sera exportada.
Diferente do método SetQtyRecords, esse utiliza uma query para melhor performance.
 
@author michael.gabriel
@since 13/07/2017
/*/
//-----------------------------------------------------------------------
Method SetQtyRecSQL() Class RedisLoadTempTableExport

	Local cQuery := ""

	cQuery := "SELECT COUNT(*) TOTREC"
	cQuery += Self:cFrom
	cQuery += Self:cWhere

	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery),'TOTRECTMP', .F., .T.)
	Self:nQtyRecords := TOTRECTMP->TOTREC
	TOTRECTMP->( dbCloseArea() )

Return

//----------------------------------------------------------------------
/*/{Protheus.doc} GetFullQuery()
Obtem os campos da query que será utilizado para gerar o 
ResultSet que será utilizado para exportação completa.
 
@author michael.gabriel
@since 13/07/2017
/*/
//-----------------------------------------------------------------------
Method GetFullQuery() Class RedisLoadTempTableExport

	Local cSelect		:= ""
	Local aStruct		:= {}
	Local nI			:= 0
	Local cTypeDB		:= TCGetDB()
	Local lX3POSLGT		:= SX3->(FieldPos("X3_POSLGT")) > 0
	Local lLJ1170MM		:= ExistBlock("Lj1170MM")
	Local cSyntaxSQL	:= ""	//retorno do PE Lj1170MM que é uma sintaxe SQL para conversao do campo MEMO

//verifica se existe algum Memo real na estrutura da tabela
	aStruct := (Self:oTable:cTable)->( DBStruct() )

	For nI := 1 to Len( aStruct )

		If aStruct[nI][2] == "M" .AND. lX3POSLGT .AND. GetSx3Cache(aStruct[nI][1], "X3_POSLGT") <> "2"

			//Este P.E. foi criado pelo motivo de sintaxe diferente de cada SGBD para converter um campo Memo Real (BLOB) para Caractere
			If lLJ1170MM
				cSyntaxSQL := ExecBlock( "Lj1170MM", .F., .F., {Self:oTable:cTable, aStruct[nI][1]} )
				If !Empty(cSyntaxSQL)
					cSelect += (cSyntaxSQL + " " + aStruct[nI][1] + ",")	//[comando alias_campo,]
				EndIf
			Else
				//Tratamento apenas para MSSQL Server
				If "MSSQL" $ cTypeDB
					cSelect += ("CONVERT(VARCHAR(4000),CONVERT(VARBINARY(4000)," + aStruct[nI][1] + " )) " + aStruct[nI][1] + ",")
				ElseIf "DB2" $ cTypeDB
					//Query em Campos Memo no DB2 infelizmente não funciona, não traz resultado nenhum
					cSelect += ""
				EndIf
				// *** O B S E R V A C A O :
				//Para banco ORACLE existia o seguinte tratamento: utl_raw.cast_to_varchar2(CAMPO)
				//Porem, soh funciona se estiver instalado o pacote UTL_RAW no banco Oracle. Por isso, foi tirado o tratamento p/ Oracle
				//onde foi criado o P.E. "Lj1170MM" p/ que o cliente trate a sintaxe conforme o pacote que ele possuir instalado no banco.
			EndIf
		Else
			cSelect += (aStruct[nI][1] + ",")
		EndIf

	Next nI

//extrai a ultima virgula
	cSelect := SubStr( cSelect, 1, Len(cSelect)-1 )

	aSize(aStruct, 0)
	aStruct := Nil

Return cSelect

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Classe: ³ RedisLoadTransferTables      ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Classe que representa as tabelas e suas configurações transferidas     º±±
±±º             ³ pela carga.                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
	Class RedisLoadTransferTables From FwSerialize
		Data aoTables

		Method New()
		Method AddTable()
	EndClass

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ New                               ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Construtor.                                                            º±±
±±º             ³                                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ Nenhum.                                                                º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Self                                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method New() Class RedisLoadTransferTables
	Self:aoTables := {}
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ AddTable                          ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Adiciona uma tabela na lista das tabelas transferidas.                 º±±
±±º             ³                                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ oTable: Objeto do tipo RedisLoadTable.                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Nenhum.                                                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method AddTable( oTable ) Class RedisLoadTransferTables
	aAdd( Self:aoTables, oTable )
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Classe: ³ RedisLoadCompleteTable       ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Classe que representa uma tabela de transferência completa.            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
	Class RedisLoadCompleteTable From FWSerialize
		Data cTable
		Data cFilter
		Data aBranches
		Data cQtyRecords

		Method New()
	EndClass

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ New                               ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Construtor.                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ cTable: Alias da tabela completa.                                      º±±
±±º             ³ aBranches: Filiais que serão transferidas.                             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Self                                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method New( cTable, aBranches ) Class RedisLoadCompleteTable
	If !Empty( cTable )
		Self:cTable := cTable
	Else
		Self:cTable := ""
	EndIf

	If !Empty( aBranches )
		Self:aBranches := aBranches
	Else
		Self:aBranches := {}
	EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Classe: ³ RedisLoadPartialTable        ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Classe que representa uma tabela de transferência parcial.             º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
	Class RedisLoadPartialTable From FWSerialize
		Data cTable
		Data cFilter
		Data aRecords
		Data cQtyRecords

		Method New()
		Method AddRecord()
	EndClass

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ New                               ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Construtor.                                                            º±±
±±º             ³                                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ cTable: Alias da tabela completa.                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Self                                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method New( cTable ) Class RedisLoadPartialTable
	If !Empty( cTable )
		Self:cTable := cTable
	Else
		Self:cTable := ""
	EndIf

	Self:aRecords := {}
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ AddRecord                         ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Adiciona um registro que deve ser transferido.                         º±±
±±º             ³                                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ nKey: Índice da tabela.                                                º±±
±±º             ³ cSeek: Chave de procura para a substituição.                           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Nenhum.                                                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method AddRecord( nKey, cSeek ) Class RedisLoadPartialTable
	aAdd( Self:aRecords, { nKey, cSeek } )
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Classe: ³ RedisLoadSpecialTable        ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Classe que representa uma tabela de transferência especial.            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
	Class RedisLoadSpecialTable From FWSerialize
		Data cTable
		Data aParams
		Data cQtyRecords

		Method New()
	EndClass

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Método: ³ New                               ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Construtor.                                                            º±±
±±º             ³                                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ cTable: Alias da tabela completa.                                      º±±
±±º             ³ aParams: Parâmetros da transferência especial.                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ Self                                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method New( cTable, aParams ) Class RedisLoadSpecialTable
	If !Empty( cTable )
		Self:cTable := cTable
	Else
		cTable := ""
	EndIf

	If !Empty( aParams )
		Self:aParams := aParams
	Else
		Self:aParams := {}
	EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º     Função: ³ UREDISL1                       ³ Autor: Vendas CRM ³ Data: 16/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º  Descrição: ³ Le um grupo de tabela e retorna seu RedisLoadTransferTables.      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Parametros: ³ Nenhum.                                                                º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º    Retorno: ³ oTransferTables: Objeto do tipo RedisLoadTransferTables.          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function UREDISL1( cTableGroup )
	Local oTransferTables	:= RedisLoadTransferTables():New()
	Local oTempTable		:= Nil
	Local aBranches			:= {}
	Local aRecords			:= {}
	Local aParams			:= {}

	DbSelectArea( "MBV" )
	DbSetOrder( 1 )
	If MBV->( DbSeek( xFilial( "MBV" ) + cTableGroup ) )
		While	MBV->MBV_FILIAL + MBV->MBV_CODGRP ==  xFilial( "MBV" ) + cTableGroup .And.;
				MBV->( !EOF() )
			oTempTable := Nil
			//tipo -> completa
			If AllTrim( MBV->MBV_TIPO ) == "1"
				oTempTable := RedisLoadCompleteTable():New( MBV->MBV_TABELA )
				aBranches := {}
				DbSelectArea( "MBX" )
				DbSetOrder( 1 )
				If MBX->( DbSeek( xFilial( "MBX" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA ) )
					While	MBX->MBX_FILIAL + MBX->MBX_CODGRP + MBX->MBX_TABELA == xFilial( "MBX" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA .And.;
							MBX->( !EOF() )
						aAdd( aBranches, MBX->MBX_FIL )
						MBX->( DbSkip() )
					End
				EndIf
				oTempTable:aBranches := aBranches
				oTempTable:cFilter := MBV->MBV_FILTRO
				oTempTable:cQtyRecords := MBV->MBV_QTDREG
				//tipo -> parcial
			ElseIf AllTrim( MBV->MBV_TIPO ) == "2"
				oTempTable := RedisLoadPartialTable():New( MBV->MBV_TABELA )
				aRecords := {}
				DbSelectArea( "MBW" )
				DbSetOrder( 1 )
				If MBW->( DbSeek( xFilial( "MBW" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA ) )
					While	MBW->MBW_FILIAL + MBW->MBW_CODGRP + MBW->MBW_TABELA == xFilial( "MBW" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA .And.;
							MBW->( !EOF() )
						aAdd( aRecords, { MBW->MBW_INDICE, MBW->MBW_SEEK  } )
						MBW->( DbSkip() )
					End
				EndIf
				oTempTable:aRecords := aRecords
				oTempTable:cFilter	:= MBV->MBV_FILTRO
				oTempTable:cQtyRecords := MBV->MBV_QTDREG
				//tipo -> especial
			ElseIf AllTrim( MBV->MBV_TIPO ) == "3"
				oTempTable := RedisLoadSpecialTable():New( MBV->MBV_TABELA )
				If MBV->MBV_TABELA == "SBI"
					aParams := Array( 2 )
					aBranches := {}
					DbSelectArea( "MBX" )
					DbSetOrder( 1 )
					If MBX->( DbSeek( xFilial( "MBX" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA ) )
						While	MBX->MBX_FILIAL + MBX->MBX_CODGRP + MBX->MBX_TABELA == xFilial( "MBX" ) + MBV->MBV_CODGRP + MBV->MBV_TABELA .And.;
								MBX->( !EOF() )
							aAdd( aBranches, MBX->MBX_FIL )
							MBX->( DbSkip() )
						End
					EndIf
					aParams[1] := aBranches
					aParams[2] := MBV->MBV_FILTRO
					oTempTable:aParams := aParams
					oTempTable:cQtyRecords := MBV->MBV_QTDREG
				EndIf
			EndIf
			aAdd( oTransferTables:aoTables, oTempTable )
			MBV->( DbSkip() )
		End
	EndIf
Return oTransferTables
